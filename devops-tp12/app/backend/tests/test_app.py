import json
import os
import sys
from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


@pytest.fixture
def client():
    with patch('app.get_conn') as mock_conn:
        mock_cursor = MagicMock()
        mock_conn.return_value.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = [
            (1, "Nota test", "Contenido test", datetime(2026, 5, 13))
        ]
        mock_cursor.fetchone.return_value = (1,)
        import app as flask_app
        flask_app.app.config['TESTING'] = True
        with flask_app.app.test_client() as test_client:
            yield test_client


def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert 'status' in json.loads(response.data)


def test_metrics_expone_formato_prometheus(client):
    response = client.get('/metrics')
    assert response.status_code == 200
    assert b'app_requests_total' in response.data


def test_get_notes(client):
    response = client.get('/api/notes')
    assert response.status_code == 200
    assert isinstance(json.loads(response.data), list)


def test_create_note(client):
    response = client.post(
        '/api/notes',
        data=json.dumps({'title': 'Test', 'content': 'Contenido'}),
        content_type='application/json'
    )
    assert response.status_code == 201


def test_create_note_sin_titulo_devuelve_400(client):
    response = client.post(
        '/api/notes',
        data=json.dumps({'content': 'Sin título'}),
        content_type='application/json'
    )
    assert response.status_code == 400
    assert 'error' in json.loads(response.data)


def test_create_note_body_vacio_devuelve_400(client):
    response = client.post(
        '/api/notes', data=json.dumps({}), content_type='application/json'
    )
    assert response.status_code == 400


def test_delete_note(client):
    response = client.delete('/api/notes/1')
    assert response.status_code == 200
