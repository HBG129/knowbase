"""CSV analysis helpers and LLM-to-SQL orchestration."""
from __future__ import annotations

import csv
import json
import math
import re
import uuid
from collections import Counter
from decimal import Decimal
from typing import Any

import duckdb
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.analysis import AnalysisRun
from app.models.document import Document
from app.models.user import User
from app.services.llm_service import chat_sync

MAX_RESULT_ROWS = 200
MAX_CHART_POINTS = 24
FORBIDDEN_SQL_RE = re.compile(
    r"\b(insert|update|delete|drop|alter|create|copy|attach|install|load|export|pragma)\b|\bread_\w+\b|\b\w+_scan\s*\(|\b(glob|range|generate_series|query|query_table|sniff_csv)\s*\(|from\s+['\"]",
    re.IGNORECASE,
)
DATASET_REF_RE = re.compile(r"\b(from|join)\s+dataset\b", re.IGNORECASE)
DATASET_CTE_RE = re.compile(r"(\bwith|,)\s+dataset(?:\s*\([^)]*\))?\s+as\s*\(", re.IGNORECASE)
SQL_COMMENT_OR_STRING_RE = re.compile(
    r"('(?:''|[^'])*')|(--[^\r\n]*)|(/\*.*?\*/)",
    re.IGNORECASE | re.DOTALL,
)


class UnsafeAnalysisQuery(ValueError):
    """Raised when generated SQL is not safe for local read-only analysis."""


class AnalysisQueryExecutionError(ValueError):
    """Raised when safe analysis SQL fails during DuckDB execution."""

    def __init__(self, message: str, sql: str):
        super().__init__(message)
        self.sql = sql


def _to_json_value(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def _read_csv_rows(file_path: str, max_rows: int | None = None) -> tuple[list[str], list[dict[str, str]]]:
    with open(file_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        columns = list(reader.fieldnames or [])
        rows = []
        for row in reader:
            rows.append({column: row.get(column, "") for column in columns})
            if max_rows is not None and len(rows) >= max_rows:
                break
    return columns, rows


def _looks_number(values: list[str]) -> bool:
    non_empty = [value for value in values if value not in ("", None)]
    if not non_empty:
        return False
    for value in non_empty:
        try:
            float(value)
        except ValueError:
            return False
    return True


def build_csv_profile(file_path: str) -> dict:
    columns, rows = _read_csv_rows(file_path)
    column_profiles = []
    for column in columns:
        values = [row.get(column, "") for row in rows]
        missing_count = sum(1 for value in values if value == "")
        profile = {
            "name": column,
            "type": "number" if _looks_number(values) else "text",
            "missing_count": missing_count,
        }
        if profile["type"] == "number":
            numbers = [float(value) for value in values if value != ""]
            profile["min"] = min(numbers) if numbers else None
            profile["max"] = max(numbers) if numbers else None
        else:
            counts = Counter(value for value in values if value != "")
            profile["top_values"] = [
                {"value": value, "count": count}
                for value, count in counts.most_common(5)
            ]
        column_profiles.append(profile)
    return {
        "row_count": len(rows),
        "column_count": len(columns),
        "columns": column_profiles,
    }


def build_csv_preview(file_path: str, max_rows: int = 50) -> dict:
    columns, rows = _read_csv_rows(file_path, max_rows=max_rows)
    return {
        "columns": columns,
        "rows": [[row.get(column, "") for column in columns] for row in rows],
        "profile": build_csv_profile(file_path),
    }


def recommended_questions(profile: dict) -> list[str]:
    columns = [column["name"] for column in profile["columns"]]
    numeric = [column["name"] for column in profile["columns"] if column["type"] == "number"]
    text = [column["name"] for column in profile["columns"] if column["type"] == "text"]
    questions = []
    if numeric and text:
        questions.append(f"Summarize {numeric[0]} by {text[0]} and identify the top category")
    if numeric:
        questions.append(f"Find anomalies and trends in {numeric[0]}")
    if len(columns) >= 2:
        questions.append("Generate a concise business analysis report for this dataset")
    return questions or ["Summarize the main characteristics of this CSV dataset"]


def _strip_sql_comments_and_strings(sql: str) -> str:
    return SQL_COMMENT_OR_STRING_RE.sub(" ", sql)


def _mask_sql_comments_and_string_contents(sql: str) -> str:
    def replacement(match: re.Match) -> str:
        token = match.group(0)
        if token.startswith("'"):
            return "''"
        return " "

    return SQL_COMMENT_OR_STRING_RE.sub(replacement, sql)


def ensure_safe_select_sql(sql: str) -> str:
    candidate = sql.strip().rstrip(";").strip()
    if not candidate:
        raise UnsafeAnalysisQuery("SQL is empty")
    if ";" in candidate:
        raise UnsafeAnalysisQuery("Only a single SELECT statement is allowed")
    lowered = candidate.lower()
    if not (lowered.startswith("select") or lowered.startswith("with")):
        raise UnsafeAnalysisQuery("Only SELECT queries are allowed")
    relation_sql = _strip_sql_comments_and_strings(candidate)
    if DATASET_CTE_RE.search(relation_sql):
        raise UnsafeAnalysisQuery("Analysis SQL cannot redefine the dataset relation")
    if not DATASET_REF_RE.search(relation_sql):
        raise UnsafeAnalysisQuery("Analysis SQL must query the dataset relation")
    operation_sql = _mask_sql_comments_and_string_contents(candidate)
    if FORBIDDEN_SQL_RE.search(operation_sql):
        raise UnsafeAnalysisQuery("Generated SQL contains a forbidden operation")
    return candidate


def execute_csv_query(file_path: str, sql: str, limit: int = MAX_RESULT_ROWS) -> dict:
    safe_sql = ensure_safe_select_sql(sql)
    con = duckdb.connect(database=":memory:")
    try:
        con.execute("create table dataset as select * from read_csv(?)", [file_path])
        con.execute("set enable_external_access=false")
        result = con.execute(f"select * from ({safe_sql}) as analysis_result limit {int(limit)}")
        columns = [description[0] for description in result.description or []]
        rows = [
            [_to_json_value(value) for value in row]
            for row in result.fetchall()
        ]
        return {"columns": columns, "rows": rows}
    finally:
        con.close()


def get_csv_document(db: Session, kb_id: str, doc_id: str) -> Document | None:
    return db.execute(
        select(Document).where(
            Document.id == doc_id,
            Document.kb_id == kb_id,
            Document.file_type == "csv",
            Document.status == "completed",
        )
    ).scalar_one_or_none()


def list_csv_datasets(db: Session, kb_id: str) -> list[dict]:
    docs = db.execute(
        select(Document)
        .where(Document.kb_id == kb_id, Document.file_type == "csv", Document.status == "completed")
        .order_by(Document.created_at.desc())
    ).scalars().all()
    datasets = []
    for doc in docs:
        profile = build_csv_profile(doc.file_path)
        datasets.append({
            "doc_id": doc.id,
            "filename": doc.filename,
            "row_count": profile["row_count"],
            "column_count": profile["column_count"],
            "columns": profile["columns"],
            "recommended_questions": recommended_questions(profile),
            "created_at": doc.created_at.isoformat() if doc.created_at else "",
        })
    return datasets


def _extract_json_object(text: str) -> dict:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = re.sub(r"^```(?:json)?", "", stripped, flags=re.IGNORECASE).strip()
        stripped = stripped.removesuffix("```").strip()
    start = stripped.find("{")
    end = stripped.rfind("}")
    if start == -1 or end == -1 or end < start:
        raise ValueError("Model did not return JSON")
    return json.loads(stripped[start:end + 1])


def _chart_from_result(chart_type: str, columns: list[str], rows: list[list[Any]], question: str) -> dict:
    chart_type = chart_type if chart_type in {"bar", "line", "pie"} else "table"
    if chart_type == "table" or len(columns) < 2 or not rows:
        chart_type = "table"
    values = [row[1] for row in rows if len(row) > 1]
    numeric_values = [
        value
        for value in values
        if not isinstance(value, bool)
        and isinstance(value, (int, float, Decimal))
        and math.isfinite(float(value))
    ]
    if len(numeric_values) != len(rows) or (chart_type == "pie" and any(value < 0 for value in numeric_values)):
        chart_type = "table"
    return {
        "type": chart_type,
        "x": columns[0] if columns else "",
        "y": columns[1] if len(columns) > 1 else "",
        "series": rows[:MAX_CHART_POINTS] if chart_type != "table" else rows,
        "title": question[:80],
    }


def _empty_chart(question: str) -> dict:
    return {
        "type": "table",
        "x": "",
        "y": "",
        "series": [],
        "title": question[:80],
    }


def _insights_from_profile(profile: dict) -> list[str]:
    insights = [
        f"{profile['row_count']} rows across {profile['column_count']} columns",
    ]
    missing = [
        column for column in profile["columns"]
        if column.get("missing_count", 0) > 0
    ]
    if missing:
        insights.append(
            "Missing values detected in " + ", ".join(column["name"] for column in missing[:3])
        )
    return insights


def run_analysis_query(db: Session, kb_id: str, doc: Document, user: User, question: str) -> dict:
    profile = build_csv_profile(doc.file_path)
    prompt = (
        "You generate safe DuckDB SQL for a local CSV relation named dataset.\n"
        "Return strict JSON with keys sql, chart_type, summary_goal. "
        "Use only SELECT queries against dataset. Do not use file functions.\n\n"
        f"Columns/profile:\n{json.dumps(profile, ensure_ascii=False)}\n\n"
        f"Question: {question}"
    )
    raw_plan = chat_sync(
        user,
        "You are a careful data analyst that writes safe read-only SQL.",
        [{"role": "user", "content": prompt}],
        temperature=0.2,
    )
    plan = _extract_json_object(raw_plan)
    sql = ensure_safe_select_sql(str(plan.get("sql", "")))
    try:
        query_result = execute_csv_query(doc.file_path, sql, MAX_RESULT_ROWS)
    except duckdb.Error as e:
        raise AnalysisQueryExecutionError(f"Generated SQL could not be executed: {e}", sql) from e
    chart = _chart_from_result(str(plan.get("chart_type", "table")), query_result["columns"], query_result["rows"], question)
    summary_prompt = (
        "Summarize this analysis result in the user's language. Keep it concise.\n"
        f"Question: {question}\nSQL: {sql}\n"
        f"Columns: {query_result['columns']}\nRows: {query_result['rows'][:20]}\n"
        f"Goal: {plan.get('summary_goal', '')}"
    )
    try:
        summary = chat_sync(
            user,
            "You summarize data analysis results for business users.",
            [{"role": "user", "content": summary_prompt}],
            temperature=0.2,
        ).strip()
    except Exception as e:
        summary = f"Summary unavailable. The SQL query completed successfully, but summary generation failed: {e}"
    insights = _insights_from_profile(profile)

    run = AnalysisRun(
        id=str(uuid.uuid4()),
        kb_id=kb_id,
        doc_id=doc.id,
        user_id=user.id,
        question=question,
        sql=sql,
        columns_json=json.dumps(query_result["columns"], ensure_ascii=False),
        rows_json=json.dumps(query_result["rows"], ensure_ascii=False),
        chart_json=json.dumps(chart, ensure_ascii=False),
        summary=summary,
        insights_json=json.dumps(insights, ensure_ascii=False),
    )
    db.add(run)
    db.flush()
    return serialize_analysis_run(run)


def save_failed_analysis_run(
    db: Session,
    kb_id: str,
    doc: Document,
    user: User,
    question: str,
    error_message: str,
    sql: str | None = None,
) -> AnalysisRun:
    run = AnalysisRun(
        id=str(uuid.uuid4()),
        kb_id=kb_id,
        doc_id=doc.id,
        user_id=user.id,
        question=question,
        sql=sql,
        columns_json="[]",
        rows_json="[]",
        chart_json=json.dumps(_empty_chart(question), ensure_ascii=False),
        summary="",
        insights_json="[]",
        error_message=error_message,
    )
    db.add(run)
    db.flush()
    return run


def serialize_analysis_run(run: AnalysisRun) -> dict:
    return {
        "id": run.id,
        "run_id": run.id,
        "kb_id": run.kb_id,
        "doc_id": run.doc_id,
        "question": run.question,
        "sql": run.sql,
        "columns": json.loads(run.columns_json or "[]"),
        "rows": json.loads(run.rows_json or "[]"),
        "chart": json.loads(run.chart_json or "{}"),
        "summary": run.summary or "",
        "insights": json.loads(run.insights_json or "[]"),
        "error_message": run.error_message,
        "created_at": run.created_at.isoformat() if run.created_at else "",
    }
