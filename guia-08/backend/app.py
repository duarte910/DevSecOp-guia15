from flask import Flask, jsonify, request, Response
from flask_cors import CORS
from prometheus_client import (
    Counter, Histogram, Gauge,
    generate_latest, CONTENT_TYPE_LATEST
)
import psycopg2, os, datetime, time

app = Flask(__name__)
CORS(app)
START_TIME = time.time()

# ── Métricas Prometheus ───────────────────────────────────
REQUEST_COUNT = Counter(
    'app_requests_total',
    'Total de requests HTTP',
    ['method', 'endpoint', 'status']
)
REQUEST_LATENCY = Histogram(
    'app_request_duration_seconds',
    'Latencia de requests en segundos',
    ['endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)
NOTES_TOTAL = Gauge(
    'app_notes_total',
    'Cantidad total de notas en la base de datos'
)
DB_ERRORS = Counter(
    'app_db_errors_total',
    'Total de errores de conexión a la base de datos'
)
APP_INFO = Gauge(
    'app_info',
    'Información de la aplicación',
    ['version', 'environment']
)
APP_INFO.labels(
    version=os.getenv('APP_VERSION', '1.0.0'),
    environment=os.getenv('APP_ENV', 'production')
).set(1)

# ── Middleware: mide latencia y cuenta requests ───────────
@app.before_request
def start_timer():
    request._start_time = time.time()

@app.after_request
def record_metrics(response):
    if request.path != '/metrics':
        latency = time.time() - getattr(request, '_start_time', time.time())
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.path,
            status=response.status_code
        ).inc()
        REQUEST_LATENCY.labels(endpoint=request.path).observe(latency)
    return response

# ── Helpers DB ────────────────────────────────────────────
def get_conn():
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        port=os.getenv('DB_PORT', '5432'),
        dbname=os.getenv('DB_NAME', 'notesdb'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )

def init_db():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id SERIAL PRIMARY KEY,
            title VARCHAR(200) NOT NULL,
            content TEXT,
            created_at TIMESTAMP DEFAULT NOW()
        )
    """)
    conn.commit()
    cur.close(); conn.close()

def update_notes_gauge():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM notes")
        count = cur.fetchone()[0]
        NOTES_TOTAL.set(count)
        cur.close(); conn.close()
    except Exception:
        DB_ERRORS.inc()

# ── Endpoints ─────────────────────────────────────────────
@app.route('/metrics')
def metrics():
    update_notes_gauge()
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route('/health')
def health():
    uptime = int(time.time() - START_TIME)
    try:
        conn = get_conn(); conn.close()
        db_status = 'connected'
    except Exception as e:
        DB_ERRORS.inc()
        db_status = f'error: {e}'
    return jsonify({
        'status': 'ok',
        'uptime_seconds': uptime,
        'db': db_status,
        'time': datetime.datetime.utcnow().isoformat()
    })

@app.route('/api/notes', methods=['GET'])
def get_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute('SELECT id, title, content, created_at FROM notes ORDER BY created_at DESC')
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([
        {'id': r[0], 'title': r[1], 'content': r[2], 'created_at': str(r[3])}
        for r in rows
    ])

@app.route('/api/notes', methods=['POST'])
def create_note():
    data = request.get_json()
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        'INSERT INTO notes (title, content) VALUES (%s, %s) RETURNING id',
        (data['title'], data.get('content', ''))
    )
    note_id = cur.fetchone()[0]
    conn.commit()
    cur.close(); conn.close()
    return jsonify({'id': note_id, 'message': 'nota creada'}), 201

@app.route('/api/notes/<int:note_id>', methods=['DELETE'])
def delete_note(note_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute('DELETE FROM notes WHERE id = %s', (note_id,))
    conn.commit()
    cur.close(); conn.close()
    return jsonify({'message': 'nota eliminada'})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
