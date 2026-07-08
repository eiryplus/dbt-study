FROM python:3.13-slim

ENV POETRY_HOME=/opt/poetry \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PATH="/opt/poetry/bin:$PATH"

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://install.python-poetry.org | python3 -

WORKDIR /usr/app

COPY pyproject.toml poetry.lock* ./
RUN poetry install --no-root --no-ansi --only main

COPY . .

ENV DBT_PROFILES_DIR=/usr/app/dbt_project

CMD ["sleep", "infinity"]
