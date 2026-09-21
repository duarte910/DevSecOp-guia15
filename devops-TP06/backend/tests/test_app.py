import pytest
import json
import sys, os
from datetime import datetime
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Mock de psycopg2 para no necesitar Postgres en los tests unitarios
from unittest.mock import patch, MagicMock

@pytest.fixture
def client():
    with patch('app.get_conn') as mock_conn:
        mock_cursor = MagicMock()
        mock_conn.return_value.cursor.return_value = mock_cursor
        # La app usa conexión y cursor como context managers.
        mock_conn.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchall.return_value = [
            (1, "Nota test", "Contenido test", datetime(2026, 5, 13))
        ]
        mock_cursor.fetchone.return_value = (1,)
        import app as flask_app
        flask_app.app.config['TESTING'] = True
        with flask_app.app.test_client() as client:
            yield client

def test_health(client):
    with patch('app.get_conn') as mock_conn:
        mock_conn.return_value  # simula conexión exitosa
        r = client.get('/health')
        assert r.status_code == 200
        data = json.loads(r.data)
        assert 'status' in data

def test_get_notes(client):
    r = client.get('/api/notes')
    assert r.status_code == 200
    data = json.loads(r.data)
    assert isinstance(data, list)

def test_create_note(client):
    r = client.post(
        '/api/notes',
        data=json.dumps({'title': 'Test', 'content': 'Contenido'}),
        content_type='application/json'
    )
    assert r.status_code == 201

def test_create_note_sin_titulo(client):
    r = client.post(
        '/api/notes',
        data=json.dumps({'content': 'Sin título'}),
        content_type='application/json'
    )
    # Debe fallar con 400 o 500 si no hay título
    assert r.status_code in [400, 500]

def test_delete_note(client):
    r = client.delete('/api/notes/1')
    assert r.status_code == 200
