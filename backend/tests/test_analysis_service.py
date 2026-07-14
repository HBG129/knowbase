import duckdb
import pytest

from app.services.analysis_service import (
    UnsafeAnalysisQuery,
    _chart_from_result,
    build_csv_profile,
    ensure_safe_select_sql,
    execute_csv_query,
    recommended_questions,
)


def test_build_csv_profile_summarizes_columns_and_quality(tmp_path):
    path = tmp_path / "sales.csv"
    path.write_text(
        "month,channel,revenue,orders\n"
        "Jan,web,1200,10\n"
        "Feb,store,950,8\n"
        "Mar,web,,12\n",
        encoding="utf-8",
    )

    profile = build_csv_profile(str(path))

    assert profile["row_count"] == 3
    assert profile["column_count"] == 4
    revenue = next(column for column in profile["columns"] if column["name"] == "revenue")
    assert revenue["type"] == "number"
    assert revenue["missing_count"] == 1
    assert revenue["min"] == 950
    assert revenue["max"] == 1200
    channel = next(column for column in profile["columns"] if column["name"] == "channel")
    assert channel["type"] == "text"
    assert channel["top_values"][0] == {"value": "web", "count": 2}


def test_recommended_questions_are_customer_readable():
    profile = {
        "row_count": 3,
        "column_count": 2,
        "columns": [
            {"name": "channel", "type": "text", "missing_count": 0},
            {"name": "revenue", "type": "number", "missing_count": 0},
        ],
    }

    questions = recommended_questions(profile)

    assert questions[0] == "Summarize revenue by channel and identify the top category"
    assert questions[1] == "Find anomalies and trends in revenue"
    assert all("�" not in question for question in questions)


@pytest.mark.parametrize(
    "sql",
    [
        "select * from dataset",
        "select created_at, updated_at from dataset",
        "select * from dataset where status = 'drop'",
        "WITH totals AS (SELECT channel, sum(revenue) revenue FROM dataset GROUP BY channel) SELECT * FROM totals",
    ],
)
def test_ensure_safe_select_sql_allows_read_only_queries(sql):
    assert ensure_safe_select_sql(sql) == sql


@pytest.mark.parametrize(
    "sql",
    [
        "delete from dataset",
        "select * from dataset; drop table dataset",
        "copy dataset to 'out.csv'",
        "install httpfs",
        "select * from read_csv_auto('secret.csv')",
        "select * from read_json_auto('secret.json')",
        "select * from glob('C:/Users/*')",
        "select * from parquet_scan('secret.parquet')",
        "select * from sqlite_scan('local.db', 'users')",
        "select * from dataset union all select * from 'secret.csv'",
        "select 1",
        "select * from range(1000000000)",
        "select * from dataset, range(1000000000)",
        "select * from dataset join generate_series(1, 1000000000) on true",
        "select * from dataset join query('select 42 as leaked') on true",
        "select * from dataset join query_table('dataset') on true",
        "select * from dataset join sniff_csv('secret.csv') on true",
        "select 1 -- dataset",
        "select 1 -- from dataset",
        "select 1 /* from dataset */",
        "select 'from dataset'",
        "select 1 as dataset",
        "with dataset as (select * from range(10)) select * from dataset",
        "with other as (select 1), dataset as (select * from range(10)) select * from dataset",
    ],
)
def test_ensure_safe_select_sql_rejects_dangerous_queries(sql):
    with pytest.raises(UnsafeAnalysisQuery):
        ensure_safe_select_sql(sql)


def test_execute_csv_query_returns_limited_rows(tmp_path):
    path = tmp_path / "sales.csv"
    path.write_text(
        "channel,revenue\n"
        "web,1200\n"
        "store,950\n"
        "web,1300\n",
        encoding="utf-8",
    )

    result = execute_csv_query(
        str(path),
        "select channel, sum(revenue) as total_revenue from dataset group by channel order by total_revenue desc",
        limit=10,
    )

    assert result["columns"] == ["channel", "total_revenue"]
    assert result["rows"] == [["web", 2500], ["store", 950]]


def test_execute_csv_query_disables_duckdb_external_file_access(tmp_path, monkeypatch):
    path = tmp_path / "sales.csv"
    path.write_text("channel,revenue\nweb,1200\n", encoding="utf-8")
    csv_path = path.as_posix().replace("'", "''")
    sql = (
        "select d.channel from dataset d "
        f"join query('select * from read_csv_auto(''{csv_path}'')') external_data on true"
    )
    monkeypatch.setattr("app.services.analysis_service.ensure_safe_select_sql", lambda candidate: candidate)

    with pytest.raises(duckdb.PermissionException, match="file system operations are disabled"):
        execute_csv_query(str(path), sql, limit=10)


def test_chart_falls_back_to_table_for_nonnumeric_values():
    chart = _chart_from_result("bar", ["category", "value"], [["A", "unknown"]], "Compare values")

    assert chart["type"] == "table"


def test_pie_chart_falls_back_to_table_for_negative_values():
    chart = _chart_from_result("pie", ["category", "value"], [["A", -1], ["B", 2]], "Share")

    assert chart["type"] == "table"


def test_chart_limits_series_without_truncating_query_rows():
    rows = [[f"item-{index}", index] for index in range(40)]

    chart = _chart_from_result("bar", ["category", "value"], rows, "Compare values")

    assert chart["type"] == "bar"
    assert chart["series"] == rows[:24]
