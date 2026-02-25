def test_health_ok(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"ok": True, "db": "up"}
    assert "X-Request-ID" in response.headers
