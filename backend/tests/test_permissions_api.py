from tests.test_auth_api import auth_headers, login_user, register_user


def _register_and_login(client, email, username):
    user = register_user(client, email=email, username=username)
    headers = auth_headers(login_user(client, email=email))
    return user, headers


def _create_kb(client, headers):
    response = client.post(
        "/api/kb",
        json={"name": "Permission Docs"},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def _invite_member(client, headers, kb_id, email, role):
    response = client.post(
        "/api/kb/" + kb_id + "/members",
        json={"email": email, "role": role},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_viewer_cannot_upload_documents(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    _, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    _, viewer_headers = _register_and_login(client, "viewer@example.com", "viewer")
    _invite_member(client, owner_headers, kb["id"], "viewer@example.com", "viewer")

    response = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("faq.txt", b"Viewer should not upload.", "text/plain")},
        headers=viewer_headers,
    )

    assert response.status_code == 403


def test_editor_can_upload_but_cannot_delete_documents(client, monkeypatch, tmp_path):
    monkeypatch.setattr("app.config.settings.UPLOAD_DIR", str(tmp_path / "uploads"))
    _, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    _register_and_login(client, "editor@example.com", "editor")
    _invite_member(client, owner_headers, kb["id"], "editor@example.com", "editor")
    editor_headers = auth_headers(login_user(client, email="editor@example.com"))

    upload = client.post(
        "/api/kb/" + kb["id"] + "/documents",
        files={"file": ("faq.txt", b"Editor can upload.", "text/plain")},
        headers=editor_headers,
    )
    assert upload.status_code == 201, upload.text

    delete_response = client.delete(
        "/api/kb/" + kb["id"] + "/documents/" + upload.json()["id"],
        headers=editor_headers,
    )

    assert delete_response.status_code == 403


def test_admin_cannot_remove_owner_member(client):
    owner, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    _register_and_login(client, "admin@example.com", "admin")
    _invite_member(client, owner_headers, kb["id"], "admin@example.com", "admin")
    admin_headers = auth_headers(login_user(client, email="admin@example.com"))

    response = client.delete(
        "/api/kb/" + kb["id"] + "/members/" + owner["id"],
        headers=admin_headers,
    )

    assert response.status_code == 403


def test_owner_role_cannot_be_assigned_by_invite(client):
    _, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    _register_and_login(client, "candidate@example.com", "candidate")

    response = client.post(
        "/api/kb/" + kb["id"] + "/members",
        json={"email": "candidate@example.com", "role": "owner"},
        headers=owner_headers,
    )

    assert response.status_code == 400


def test_owner_cannot_change_member_role_to_owner(client):
    _, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    member, _ = _register_and_login(client, "member@example.com", "member")
    _invite_member(client, owner_headers, kb["id"], "member@example.com", "viewer")

    response = client.patch(
        "/api/kb/" + kb["id"] + "/members/" + member["id"],
        json={"role": "owner"},
        headers=owner_headers,
    )

    assert response.status_code == 400


def test_owner_member_role_cannot_be_changed(client):
    owner, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)

    response = client.patch(
        "/api/kb/" + kb["id"] + "/members/" + owner["id"],
        json={"role": "viewer"},
        headers=owner_headers,
    )

    assert response.status_code == 403


def test_invalid_member_role_update_is_rejected(client):
    _, owner_headers = _register_and_login(client, "owner@example.com", "owner")
    kb = _create_kb(client, owner_headers)
    member, _ = _register_and_login(client, "member@example.com", "member")
    _invite_member(client, owner_headers, kb["id"], "member@example.com", "viewer")

    response = client.patch(
        "/api/kb/" + kb["id"] + "/members/" + member["id"],
        json={"role": "superuser"},
        headers=owner_headers,
    )

    assert response.status_code == 400
