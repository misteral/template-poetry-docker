FROM python:3.12-alpine AS builder

RUN apk add build-base libffi-dev curl
RUN pip install poetry==1.8.3
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    WORKING_DIR=/app/

WORKDIR $WORKING_DIR

COPY pyproject.toml poetry.lock ./
RUN touch README.md

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --without dev --no-root

ENV VIRTUAL_ENV="$WORKING_DIR.venv" \
    PATH="$WORKING_DIR.venv/bin:$PATH"

### Production runtime
FROM python:3.12-alpine AS runtime

ENV WORKING_DIR=/app/
WORKDIR $WORKING_DIR

ENV VIRTUAL_ENV="$WORKING_DIR.venv" \
    PATH="$WORKING_DIR.venv/bin:$PATH"

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY [".", "$WORKING_DIR"]



# Create a new group `app` with Group ID `1000`.
RUN addgroup --gid 1000 app
RUN adduser app -h /app -u 1000 -G app -DH
USER 1000

EXPOSE 8889

# ENTRYPOINT ["python", "-m", "izetta.main"]
# CMD ["fastapi", "run", "src/main.py", "--port", "8889", "--host", "0.0.0.0"]
