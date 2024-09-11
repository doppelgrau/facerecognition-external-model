FROM python:slim AS builder

COPY Makefile /app/

RUN apt update -yq \
    && apt install -yq bzip2 cmake g++ make wget \
    && pip wheel -w /app/ dlib \
    && make -C /app/ download-models

FROM python:slim

COPY --from=builder /app/dlib*.whl /tmp/
COPY --from=builder /app/vendor/ /app/vendor/
COPY facerecognition-external-model.py /app/

RUN pip install flask numpy gunicorn \
    && pip install --no-index -f /tmp/ dlib \
    && rm /tmp/dlib*.whl

WORKDIR /app/

EXPOSE 5000

ARG GUNICORN_WORKERS="1"
ENV GUNICORN_WORKERS=${GUNICORN_WORKERS}
ENV API_KEY=some-super-secret-api-key
ENV FLASK_APP=facerecognition-external-model.py

CMD ["gunicorn"  , "--bind", "[::]:5000", "--timeout", "300", "--workers", "${GUNICORN_WORKERS}", "facerecognition-external-model:app", "--threads", "${GUNICORN_WORKERS}", "--access-logfile", "-"]
