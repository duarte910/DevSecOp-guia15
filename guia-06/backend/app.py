from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2, os, datetime

app = Flask(__name__)
CORS(app)

def get_conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "notesdb"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres")
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
    cur.close()
    conn.close()

@app.route("/health")
def health():
    try:
        conn = get_conn()
        conn.close()
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {e}"
    return jsonify({
        "status": "ok",
        "db": db_status,
        "time": datetime.datetime.utcnow().isoformat()
    })

@app.route("/api/notes", methods=["GET"])
def get_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, title, content, created_at FROM notes ORDER BY created_at DESC")
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([
        {"id": r[0], "title": r[1], "content": r[2], "created_at": str(r[3])}
        for r in rows
    ])

@app.route("/api/notes", methods=["POST"])
def create_note():
    data = request.get_json()
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO notes (title, content) VALUES (%s, %s) RETURNING id",
        (data["title"], data.get("content", ""))
    )
    note_id = cur.fetchone()[0]
    conn.commit()
    cur.close(); conn.close()
    return jsonify({"id": note_id, "message": "nota creada"}), 201

@app.route("/api/notes/<int:note_id>", methods=["DELETE"])
def delete_note(note_id):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM notes WHERE id = %s", (note_id,))
    conn.commit()
    cur.close(); conn.close()
    return jsonify({"message": "nota eliminada"})

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
