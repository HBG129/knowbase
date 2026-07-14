"""Schemas for CSV data analysis."""
from typing import Any, Literal

from pydantic import BaseModel


class AnalysisQueryRequest(BaseModel):
    doc_id: str
    question: str


class AnalysisColumnTopValue(BaseModel):
    value: str
    count: int


class AnalysisColumnProfile(BaseModel):
    name: str
    type: Literal["number", "text"]
    missing_count: int
    min: float | None = None
    max: float | None = None
    top_values: list[AnalysisColumnTopValue] | None = None


class AnalysisCsvProfile(BaseModel):
    row_count: int
    column_count: int
    columns: list[AnalysisColumnProfile]


class AnalysisDatasetResponse(BaseModel):
    doc_id: str
    filename: str
    row_count: int
    column_count: int
    columns: list[AnalysisColumnProfile]
    recommended_questions: list[str]
    created_at: str


class AnalysisPreviewResponse(BaseModel):
    columns: list[str]
    rows: list[list[str]]
    profile: AnalysisCsvProfile


class AnalysisChartSpec(BaseModel):
    type: Literal["bar", "line", "pie", "table"]
    x: str
    y: str
    series: list[list[Any]]
    title: str


class AnalysisRunResponse(BaseModel):
    id: str
    run_id: str
    kb_id: str
    doc_id: str
    question: str
    sql: str | None
    columns: list[str]
    rows: list[list[Any]]
    chart: AnalysisChartSpec
    summary: str
    insights: list[str]
    error_message: str | None = None
    created_at: str
