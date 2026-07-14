"""CSV data analysis API."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database import get_db
from app.models.analysis import AnalysisRun
from app.models.user import User
from app.schemas.analysis import (
    AnalysisDatasetResponse,
    AnalysisPreviewResponse,
    AnalysisQueryRequest,
    AnalysisRunResponse,
)
from app.services.analysis_service import (
    AnalysisQueryExecutionError,
    UnsafeAnalysisQuery,
    build_csv_preview,
    get_csv_document,
    list_csv_datasets,
    run_analysis_query,
    save_failed_analysis_run,
    serialize_analysis_run,
)
from app.services.knowledge_base_service import get_user_role

router = APIRouter()


def _require_kb_access(db: Session, kb_id: str, user: User) -> None:
    if get_user_role(db, kb_id, user.id) is None:
        raise HTTPException(status_code=403, detail="Access denied")


@router.get("/{kb_id}/analysis/datasets", response_model=list[AnalysisDatasetResponse])
def datasets(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _require_kb_access(db, kb_id, user)
    return list_csv_datasets(db, kb_id)


@router.get(
    "/{kb_id}/analysis/datasets/{doc_id}/preview",
    response_model=AnalysisPreviewResponse,
)
def dataset_preview(
    kb_id: str,
    doc_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_kb_access(db, kb_id, user)
    doc = get_csv_document(db, kb_id, doc_id)
    if doc is None:
        raise HTTPException(status_code=404, detail="CSV dataset not found")
    return build_csv_preview(doc.file_path)


@router.post("/{kb_id}/analysis/query", response_model=AnalysisRunResponse)
def query_dataset(
    kb_id: str,
    data: AnalysisQueryRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_kb_access(db, kb_id, user)
    question = data.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty")
    doc = get_csv_document(db, kb_id, data.doc_id)
    if doc is None:
        raise HTTPException(status_code=404, detail="CSV dataset not found")
    if not user.api_key or not user.api_provider:
        raise HTTPException(status_code=400, detail="Configure an API key in Settings before running analysis")
    try:
        return run_analysis_query(db, kb_id, doc, user, question)
    except AnalysisQueryExecutionError as e:
        save_failed_analysis_run(db, kb_id, doc, user, question, str(e), sql=e.sql)
        db.commit()
        raise HTTPException(status_code=400, detail=str(e))
    except UnsafeAnalysisQuery as e:
        save_failed_analysis_run(db, kb_id, doc, user, question, str(e))
        db.commit()
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        save_failed_analysis_run(db, kb_id, doc, user, question, str(e))
        db.commit()
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{kb_id}/analysis/runs", response_model=list[AnalysisRunResponse])
def list_runs(kb_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    _require_kb_access(db, kb_id, user)
    runs = db.execute(
        select(AnalysisRun)
        .where(AnalysisRun.kb_id == kb_id, AnalysisRun.user_id == user.id)
        .order_by(AnalysisRun.created_at.desc())
    ).scalars().all()
    return [serialize_analysis_run(run) for run in runs]


@router.get("/{kb_id}/analysis/runs/{run_id}", response_model=AnalysisRunResponse)
def get_run(
    kb_id: str,
    run_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_kb_access(db, kb_id, user)
    run = db.execute(
        select(AnalysisRun).where(
            AnalysisRun.id == run_id,
            AnalysisRun.kb_id == kb_id,
            AnalysisRun.user_id == user.id,
        )
    ).scalar_one_or_none()
    if run is None:
        raise HTTPException(status_code=404, detail="Analysis run not found")
    return serialize_analysis_run(run)
