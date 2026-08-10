from pathlib import Path
import json
import re
import shutil
import subprocess
import tomllib

import pytest


def test_runtime_dependencies_include_lxml_for_docx_parser():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
    dependencies = data["project"]["dependencies"]

    assert any(dep.lower().startswith("lxml") for dep in dependencies)


def test_runtime_dependencies_include_duckdb_for_csv_analysis():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
    dependencies = data["project"]["dependencies"]

    assert any(dep.lower().startswith("duckdb") for dep in dependencies)


def test_frontend_uses_audited_next_and_bundled_postcss_versions():
    repo_root = Path(__file__).resolve().parents[2]
    package = json.loads((repo_root / "frontend" / "package.json").read_text(encoding="utf-8"))
    lock = json.loads((repo_root / "frontend" / "package-lock.json").read_text(encoding="utf-8"))

    assert package["dependencies"]["next"] == "15.5.23"
    assert package["overrides"]["next"]["postcss"] == "8.5.26"
    assert package["overrides"]["nanoid"] == "3.3.18"
    assert lock["packages"][""]["dependencies"]["next"] == "15.5.23"
    assert lock["packages"]["node_modules/next"]["version"] == "15.5.23"
    assert lock["packages"]["node_modules/postcss"]["version"] == "8.5.26"
    assert lock["packages"]["node_modules/nanoid"]["version"] == "3.3.18"


def test_backend_dependencies_enforce_current_security_floors():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))
    dependencies = data["project"]["dependencies"]

    assert "aiohttp>=3.14.3" in dependencies
    assert "cryptography>=50.0.0" in dependencies


def test_frontend_overrides_next_sharp_to_patched_version():
    repo_root = Path(__file__).resolve().parents[2]
    package = json.loads((repo_root / "frontend" / "package.json").read_text(encoding="utf-8"))
    lock = json.loads((repo_root / "frontend" / "package-lock.json").read_text(encoding="utf-8"))

    assert package["overrides"]["next"]["sharp"] == "0.35.3"
    assert lock["packages"]["node_modules/sharp"]["version"] == "0.35.3"


def test_backend_packager_includes_duckdb_hidden_import():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "package-backend.bat"

    assert "--hidden-import duckdb" in script.read_text(encoding="utf-8")


def test_backend_packager_fails_if_previous_outputs_remain_locked():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "package-backend.bat"
    content = script.read_text(encoding="utf-8")

    assert "Failed to remove previous backend executable" in content
    assert "Failed to remove previous backend build directory" in content
    assert "Failed to remove previous backend spec file" in content


def test_desktop_installer_embeds_fixed_webview2_runtime():
    repo_root = Path(__file__).resolve().parents[2]
    tauri_config = json.loads(
        (repo_root / "frontend" / "src-tauri" / "tauri.conf.json").read_text(
            encoding="utf-8"
        )
    )

    assert tauri_config["bundle"]["windows"]["webviewInstallMode"] == {
        "type": "fixedRuntime",
        "path": "./WebView2.FixedVersionRuntime.x64",
    }


def test_desktop_packager_prepares_a_verified_fixed_webview2_runtime():
    repo_root = Path(__file__).resolve().parents[2]
    package_script = (repo_root / "package-desktop.bat").read_text(encoding="utf-8")
    runtime_script = (
        repo_root / "scripts" / "prepare-webview2-fixed-runtime.ps1"
    ).read_text(encoding="utf-8")

    assert "prepare-webview2-fixed-runtime.ps1" in package_script
    assert '$version = "150.0.4078.99"' in runtime_script
    assert 'Microsoft.WebView2.FixedVersionRuntime.$version.x64.cab' in runtime_script
    assert "https://msedge.sf.dl.delivery.mp.microsoft.com/" in runtime_script
    assert "2E69CDC3D304441562C7C2A8C21948C3B8E69DC7629D912EF853E41147220BDA" in runtime_script
    assert "Get-FileHash" in runtime_script
    assert "SHA256" in runtime_script
    assert "$downloadAttempts = 3" in runtime_script
    assert "msedgewebview2.exe" in runtime_script
    assert "if (Test-PreparedRuntime) {" not in runtime_script
    assert "Copy-Item -Destination $runtimeRoot -Recurse -Force" in runtime_script
    assert "Move-Item -LiteralPath $extractedRuntime" not in runtime_script


def test_packaged_backend_health_check_uses_backend_port_env_and_cleans_up():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "check-packaged-backend-health.ps1"

    content = script.read_text(encoding="utf-8")

    assert "KNOWBASE_BACKEND_PORT" in content
    assert "Invoke-RestMethod" in content
    assert "Stop-Process" in content
    assert "KnowBaseBackend" in content
    assert "RedirectStandardOutput" in content
    assert "RedirectStandardError" in content
    assert "Normalize-ProcessPathEnvironment" in content
    assert "Remove-Item Env:Path" in content
    assert "Stop-AndWaitForProcess" in content
    assert "Remove-PathWithRetry" in content
    assert ".Dispose()" in content
    assert "Packaged backend stderr" in content
    assert "data\\packaged-backend-health" not in content
    assert ".tmp" in content
    assert "Remove-Item" in content
    assert "usingDefaultDataDir" in content
    assert '"http://127.0.0.1:$Port/openapi.json"' in content
    assert '"/api/kb/{kb_id}/analysis/datasets"' in content
    assert '"/api/kb/{kb_id}/analysis/query"' in content
    assert '"/api/kb/{kb_id}/analysis/runs"' in content
    assert "AnalysisDatasetResponse" in content
    assert "AnalysisRunResponse" in content


def test_release_preflight_smoke_artifact_uses_temp_directory():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "check-release-preflight.ps1"
    content = script.read_text(encoding="utf-8")

    assert "data\\release-preflight-smoke" not in content
    assert ".tmp" in content
    assert "prepare-release-package.ps1" in content
    assert "-MinInstallerBytes 1" in content
    assert "KnowBaseSupportTools.zip" in content
    assert "README.txt" in content
    assert "backup-local-data.ps1" in content
    assert "restore-local-data.ps1" in content
    assert "remove-local-data.ps1" in content
    assert "SHA256SUMS.txt" in content
    assert "RELEASE_VALIDATION_ISSUE_DRAFT.md" in content
    assert "Valid signature verified" in content
    assert '"Thumbprint:"' in content
    assert "Unsigned approver:" in content
    assert "Release-notes disclosure:" in content
    assert "ProductVersion, signature status, installed executable path" in content


def test_complete_bilingual_localization_is_enforced_by_ci_and_release_preflight():
    repo_root = Path(__file__).resolve().parents[2]
    checker = repo_root / "scripts" / "check-i18n-coverage.ps1"
    preflight = (repo_root / "scripts" / "check-release-preflight.ps1").read_text(
        encoding="utf-8"
    )
    workflow = (repo_root / ".github" / "workflows" / "ci.yml").read_text(
        encoding="utf-8"
    )

    assert checker.is_file()
    checker_content = checker.read_text(encoding="utf-8")
    assert "Dictionary key parity" in checker_content
    assert "Translation usage keys" in checker_content
    assert "Hardcoded customer-facing copy" in checker_content
    assert 'check-i18n-coverage.ps1' in preflight
    assert 'check-i18n-coverage.ps1' in workflow


def test_release_package_passes_installer_size_threshold_to_artifact_check():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "prepare-release-package.ps1"
    content = script.read_text(encoding="utf-8")

    assert "[int64]$MinInstallerBytes = 50000000" in content
    assert "-MinInstallerBytes $MinInstallerBytes" in content


def test_release_package_requires_signature_or_explicit_unsigned_opt_in():
    repo_root = Path(__file__).resolve().parents[2]
    release_script = (repo_root / "scripts" / "prepare-release-package.ps1").read_text(encoding="utf-8")
    signature_script = (repo_root / "scripts" / "check-code-signature.ps1").read_text(encoding="utf-8")
    preflight = (repo_root / "scripts" / "check-release-preflight.ps1").read_text(encoding="utf-8")
    release_process = (repo_root / "docs" / "release-process.md").read_text(encoding="utf-8")

    assert "[switch]$AllowUnsigned" in release_script
    assert '$signatureStatus -eq "NotSigned" -and $AllowUnsigned' in release_script
    assert '$signatureStatus -ne "Valid"' in release_script
    assert '$signature.Status -eq "NotSigned" -and $AllowUnsigned' in signature_script
    assert '$signature.Status -ne "Valid"' in signature_script
    assert "explicitly approved unsigned builds" in release_script
    assert "does not permit invalid or untrusted signatures" in release_process
    assert "knowbase-release-package-stage-" in release_script
    assert "$stagedInstallerPath" in release_script
    assert "Copy-Item -LiteralPath $stagedInstallerPath -Destination $installerPath" in release_script
    assert "Remove-Item -LiteralPath $resolvedStagingPath.Path -Recurse -Force" in release_script
    assert "-AllowUnsigned" in preflight
    assert "explicitly approved unsigned validation or release builds" in release_process


def test_release_package_removes_stale_installers_before_writing_current_release():
    repo_root = Path(__file__).resolve().parents[2]
    release_script = (repo_root / "scripts" / "prepare-release-package.ps1").read_text(
        encoding="utf-8"
    )
    preflight = (repo_root / "scripts" / "check-release-preflight.ps1").read_text(
        encoding="utf-8"
    )

    assert 'Get-ChildItem -LiteralPath $OutputDir -Filter "KnowBase_*_x64-setup.exe"' in release_script
    assert "Remove-Item -LiteralPath $_.FullName -Force" in release_script
    assert "$staleInstallerPath" in preflight
    assert "Release package smoke check retained a stale installer" in preflight


def test_release_validation_records_signature_policy_evidence():
    repo_root = Path(__file__).resolve().parents[2]
    issue_template = (
        repo_root / ".github" / "ISSUE_TEMPLATE" / "release_validation.yml"
    ).read_text(encoding="utf-8")
    release_script = (repo_root / "scripts" / "prepare-release-package.ps1").read_text(
        encoding="utf-8"
    )
    release_process = (repo_root / "docs" / "release-process.md").read_text(
        encoding="utf-8"
    )
    release_notes_template = (
        repo_root / "docs" / "release-notes-template.md"
    ).read_text(encoding="utf-8")

    assert "id: signature_policy" in issue_template
    assert "Valid signature verified" in issue_template
    assert "Unsigned build explicitly approved and disclosed" in issue_template
    assert "Signature invalid or undecided - block release" in issue_template
    assert "id: signature_evidence" in issue_template
    assert "Unsigned approver, approval date, and exact release-notes disclosure" in issue_template
    assert "## Signature Policy Decision" in release_script
    assert "$signatureThumbprint = [string]$installerSignature.SignerCertificate.Thumbprint" in release_script
    assert '"Signer: $signatureSigner"' in release_script
    assert '"Thumbprint: $signatureThumbprint"' in release_script
    assert "Thumbprint: [certificate thumbprint or blank]" in release_notes_template
    assert "Unsigned approver:" in release_script
    assert "Approval date:" in release_script
    assert "Release-notes disclosure:" in release_script
    assert "record the signer or the unsigned approver, approval date, and exact release-notes disclosure" in release_process


def test_release_validation_requires_an_explicit_ready_gate_attestation():
    repo_root = Path(__file__).resolve().parents[2]
    issue_template = (
        repo_root / ".github" / "ISSUE_TEMPLATE" / "release_validation.yml"
    ).read_text(encoding="utf-8")
    release_docs_check = (repo_root / "scripts" / "check-release-docs.ps1").read_text(
        encoding="utf-8"
    )

    gate_text = (
        "A Ready decision is selected only when every required validation check above is complete; "
        "otherwise the release decision is Block release and failures are documented."
    )
    assert "id: release_gate" in issue_template
    assert gate_text in issue_template
    gate_section = issue_template.split("id: release_gate", 1)[1].split("id: release_decision", 1)[0]
    assert "required: true" in gate_section
    assert gate_text in release_docs_check


def test_support_info_rejects_health_url_query_parameters(tmp_path):
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "collect-support-info.ps1"
    health_url = "http://127.0.0.1:65534/api/health?token=secret"
    powershell = shutil.which("powershell") or shutil.which("pwsh")
    if powershell is None:
        pytest.skip("PowerShell is required to exercise the support-info script")

    result = subprocess.run(
        [
            powershell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
            "-OutputDir",
            str(tmp_path),
            "-HealthUrl",
            health_url,
        ],
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )

    output = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout + result.stderr)
    normalized_output = " ".join(output.split())

    assert result.returncode != 0
    assert "HealthUrl must be a local HTTP /api/health endpoint" in normalized_output
    assert "query, or fragment." in normalized_output
    assert not list(tmp_path.glob("knowbase-support-info-*.md"))


def test_pytest_discovers_only_tests_directory_by_default():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))

    assert data["tool"]["pytest"]["ini_options"]["testpaths"] == ["tests"]


def test_pytest_disables_cache_provider_for_restricted_workspaces():
    pyproject = Path(__file__).resolve().parents[1] / "pyproject.toml"
    data = tomllib.loads(pyproject.read_text(encoding="utf-8"))

    assert data["tool"]["pytest"]["ini_options"]["addopts"] == "-p no:cacheprovider"


def test_project_status_does_not_publish_a_stale_backend_test_count():
    repo_root = Path(__file__).resolve().parents[2]
    project_status = (repo_root / "docs" / "project-status.md").read_text(encoding="utf-8")
    release_docs_check = (repo_root / "scripts" / "check-release-docs.ps1").read_text(
        encoding="utf-8"
    )

    status_line = "Backend test suite passes locally."
    assert status_line in project_status
    assert not re.search(r"Backend test suite passes locally:\s*\d+ tests", project_status)
    assert f'Needle = "{status_line}"' in release_docs_check


def test_agents_plan_records_clean_production_dependency_audit_gate():
    repo_root = Path(__file__).resolve().parents[2]
    agents_plan = (repo_root / "AGENTS.md").read_text(encoding="utf-8")
    project_status = (repo_root / "docs" / "project-status.md").read_text(encoding="utf-8")
    release_docs_check = (repo_root / "scripts" / "check-release-docs.ps1").read_text(
        encoding="utf-8"
    )

    audit_command = "npm audit --omit=dev --audit-level=high"
    clean_status = "Frontend production dependency audit is release-clean"
    assert audit_command in agents_plan
    assert clean_status in agents_plan
    assert clean_status in project_status
    assert "Frontend production dependency audit is not release-clean" not in agents_plan
    assert "Frontend production dependency audit is not release-clean" not in project_status
    assert audit_command in release_docs_check
    assert clean_status in release_docs_check


def test_release_package_drafts_include_csv_analysis_validation():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "prepare-release-package.ps1"
    content = script.read_text(encoding="utf-8")

    assert "CSV data analysis with the Analysis tab" in content
    assert "- CSV data analysis in Analysis tab: not tested" in content
    assert "- [ ] CSV Analysis tab preview, query, chart, summary, and history work." in content


def test_installed_app_check_reports_build_identity():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "check-installed-app.ps1"
    content = script.read_text(encoding="utf-8")

    assert "## Build Identity" in content
    assert "Get-AuthenticodeSignature" in content
    assert "ProductVersion" in content
    assert "Backend process path" in content
    assert "$backendListeners[0].OwningProcess -in $backendProcessIds" in content
    assert 'Add-Check "Backend listener identity"' in content
    assert 'Add-Check "Backend process install path"' in content


def test_release_package_support_readme_explains_validation_report():
    repo_root = Path(__file__).resolve().parents[2]
    script = repo_root / "scripts" / "prepare-release-package.ps1"
    content = script.read_text(encoding="utf-8")
    release_docs_check = (repo_root / "scripts" / "check-release-docs.ps1").read_text(encoding="utf-8")

    identity_description = (
        "ProductVersion, signature status, installed executable path, "
        "and backend process path when available."
    )
    assert "Desktop\\KnowBaseValidation" in content
    assert identity_description in content
    assert identity_description in release_docs_check


def test_local_data_removal_includes_webview_profile():
    repo_root = Path(__file__).resolve().parents[2]
    script = (repo_root / "scripts" / "remove-local-data.ps1").read_text(encoding="utf-8")

    assert "$WebViewDataDir" in script
    assert 'Join-Path $env:LOCALAPPDATA "com.hbg129.knowbase"' in script
    assert "WebView data directory" in script
    assert "Removed WebView data directory" in script


def test_desktop_workflow_health_checks_packaged_backend_before_upload():
    repo_root = Path(__file__).resolve().parents[2]
    workflow = (repo_root / ".github" / "workflows" / "desktop-package.yml").read_text(
        encoding="utf-8"
    )

    package_index = workflow.index("- name: Build desktop package")
    health_index = workflow.index("- name: Verify packaged backend health")
    upload_index = workflow.index("- name: Upload backend executable")

    assert package_index < health_index < upload_index
    assert ".\\scripts\\check-packaged-backend-health.ps1" in workflow
    assert '      - "scripts/check-packaged-backend-health.ps1"' in workflow


def test_ci_workflows_gate_frontend_build_with_production_dependency_audit():
    repo_root = Path(__file__).resolve().parents[2]
    workflow_paths = [
        repo_root / ".github" / "workflows" / "ci.yml",
        repo_root / ".github" / "workflows" / "desktop-package.yml",
    ]

    for workflow_path in workflow_paths:
        content = workflow_path.read_text(encoding="utf-8")
        install_index = content.index("run: npm ci")
        audit_index = content.index("run: npm audit --omit=dev --audit-level=high")
        build_index = content.index("run: npm run build")

        assert install_index < audit_index < build_index


def test_ci_workflows_audit_python_dependencies():
    repo_root = Path(__file__).resolve().parents[2]
    pyproject = (repo_root / "backend" / "pyproject.toml").read_text(encoding="utf-8")
    workflow_paths = [
        repo_root / ".github" / "workflows" / "ci.yml",
        repo_root / ".github" / "workflows" / "desktop-package.yml",
    ]

    assert "pip-audit>=2.9,<3" in pyproject
    for workflow_path in workflow_paths:
        content = workflow_path.read_text(encoding="utf-8")
        assert "-m pip_audit --local --strict" in content
        assert content.index("-m pip_audit --local --strict") < content.index("-m pytest")


def test_github_workflows_use_node24_action_runtimes_and_current_miniconda_inputs():
    repo_root = Path(__file__).resolve().parents[2]
    ci_workflow = (repo_root / ".github" / "workflows" / "ci.yml").read_text(
        encoding="utf-8"
    )
    desktop_workflow = (
        repo_root / ".github" / "workflows" / "desktop-package.yml"
    ).read_text(encoding="utf-8")
    workflows = ci_workflow + desktop_workflow

    assert "actions/checkout@v7" in ci_workflow
    assert "actions/setup-node@v7" in ci_workflow
    assert "actions/setup-python@v6" in ci_workflow
    assert "actions/checkout@v7" in desktop_workflow
    assert "actions/setup-node@v7" in desktop_workflow
    assert "actions/upload-artifact@v7" in desktop_workflow
    assert "conda-incubator/setup-miniconda@v4" in desktop_workflow
    assert "auto-activate: true" in desktop_workflow
    assert "activate-environment: base" in desktop_workflow
    assert "channels: defaults" in desktop_workflow
    assert "auto-activate-base" not in workflows


def test_analysis_chart_uses_zero_baseline_and_bounded_bar_width():
    repo_root = Path(__file__).resolve().parents[2]
    source = (repo_root / "frontend" / "src" / "components" / "kb" / "analysis-panel.tsx").read_text(
        encoding="utf-8"
    )

    assert "const minValue = Math.min(...values, 0);" in source
    assert "const maxValue = Math.max(...values, 0);" in source
    assert "const zeroY = scaleY(0);" in source
    assert "height={Math.abs(point.y - zeroY)}" in source
    assert "Math.max(2," in source
    assert "Math.max(12," not in source


def test_analysis_panel_distinguishes_load_errors_and_guards_dataset_context():
    repo_root = Path(__file__).resolve().parents[2]
    source = (repo_root / "frontend" / "src" / "components" / "kb" / "analysis-panel.tsx").read_text(
        encoding="utf-8"
    )

    assert "if (error && datasets.length === 0)" in source
    assert "onClick={fetchDatasets}" in source
    assert "let cancelled = false;" in source
    assert "if (!cancelled) setPreview(data);" in source
    assert "setSelectedDocId(run.doc_id);" in source


def test_release_process_runs_installed_check_from_extracted_support_tools():
    repo_root = Path(__file__).resolve().parents[2]
    release_process = repo_root / "docs" / "release-process.md"
    content = release_process.read_text(encoding="utf-8")
    release_docs_check = (repo_root / "scripts" / "check-release-docs.ps1").read_text(encoding="utf-8")

    extraction_instruction = "Extract `KnowBaseSupportTools.zip` into a folder named `support-tools`."
    assert extraction_instruction in content
    assert extraction_instruction in release_docs_check
    assert "cd .\\support-tools" in content
    assert "-File .\\check-installed-app.ps1" in content
    assert ".\\scripts\\check-installed-app.ps1" not in content
