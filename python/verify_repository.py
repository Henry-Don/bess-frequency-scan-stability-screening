"""Verify the public repository structure and reject generated artifacts."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]

REQUIRED = (
    "README.md",
    "README.zh-CN.md",
    "CHANGELOG.md",
    "CHANGELOG.zh-CN.md",
    "VERSION",
    ".github/workflows/ci.yml",
    ".github/workflows/pages.yml",
    "config/README.md",
    "config/README.zh-CN.md",
    "results/README.md",
    "results/README.zh-CN.md",
    "models/bess_frequency_scan.slx",
    "scripts/init_frequency_scan.m",
    "scripts/run_frequency_scan.m",
    "scripts/run_scr_interaction_scan.m",
    "scripts/run_pll_risk_map.m",
    "scripts/run_time_domain_validation.m",
    "scripts/generate_portfolio_media.m",
    "tests/run_all_checks.m",
    "python/verify_repository.py",
    "site/index.html",
    "site/index.zh-CN.html",
    "site/styles.css",
    "docs/system_architecture.svg",
    "docs/control_architecture.svg",
    "docs/model_description.md",
    "docs/model_description.zh-CN.md",
    "docs/project_technical_guide.md",
    "docs/project_technical_guide.zh-CN.md",
    "docs/project_technical_guide.pdf",
    "docs/project_technical_guide.zh-CN.pdf",
    "docs/verification_summary.md",
    "docs/verification_summary.zh-CN.md",
    "docs/releases/v0.6.1.md",
    "docs/releases/v0.6.1.zh-CN.md",
    "docs/images/model_frequency_scan.png",
    "docs/images/dq_admittance_response.png",
    "docs/images/pll_scr_risk_map.png",
    "docs/images/time_domain_validation.png",
    "docs/media/bess_demo_poster.png",
    "docs/media/bess_demo.gif",
    "docs/media/bess_demo.mp4",
    "tools/package_release.ps1",
)

FORBIDDEN_SUFFIXES = (".slxc", ".asv", ".autosave", ".m~")
FORBIDDEN_PARTS = {"slprj", "dist"}


def published_files() -> list[Path]:
    result = subprocess.run(
        [
            "git",
            "-c",
            f"safe.directory={ROOT.as_posix()}",
            "-C",
            str(ROOT),
            "ls-files",
        ],
        capture_output=True,
        check=False,
        text=True,
    )
    if result.returncode == 0:
        return [ROOT / name for name in result.stdout.splitlines() if name]
    return [path for path in ROOT.rglob("*") if path.is_file()]


def main() -> int:
    missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    version_issue = version != "v0.6.1"
    unwanted = []
    for path in published_files():
        relative = path.relative_to(ROOT)
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            unwanted.append(str(relative))
        if any(part.lower() in FORBIDDEN_PARTS for part in relative.parts):
            unwanted.append(str(relative))

    if missing:
        print("Missing required files:")
        print("\n".join(f"  - {name}" for name in missing))
    if unwanted:
        print("Generated files must not be published:")
        print("\n".join(f"  - {name}" for name in sorted(set(unwanted))))
    if version_issue:
        print(f"Unexpected VERSION: {version}")

    if missing or unwanted or version_issue:
        return 1

    print(f"Repository structure check passed: {len(REQUIRED)} required files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
