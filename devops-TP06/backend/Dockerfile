# ── Stage 1: builder ────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: imagen final (sin herramientas de build) ───
FROM python:3.12-slim AS final

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app

# Copiar solo las dependencias instaladas desde el builder
COPY --from=builder /install /usr/local

# Copiar el código
COPY app.py .

# Script de inicio que espera a que Postgres esté listo
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Usuario no-root
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

EXPOSE 5000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
