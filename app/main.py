import os
from fastapi import FastAPI
from app.worker import celery_app, sample_task

app = FastAPI()


@app.get("/health")
def health():
    return {"status": "ok!"}


@app.post("/task")
def run_task():
    result = sample_task.delay()
    return {"task_id": result.id}
