# Moonlit Vigil contributor / AI handoff

## Start here
Read README.md, ASSET_LICENSES.md, docs/STATUS.md, docs/ROADMAP.md and docs/TESTING.md. This repository is the standalone 2D line. No private paths or other project checkouts are required.

## Working rules
- Keep changes scoped; do not revert other contributors. Coordinate file ownership for concurrent work.
- Preserve character/background visual quality. Do not enable failed placeholder VFX just because a technical test passes.
- Inspect actual game frames. Freeze travel to verify local wing/body/tail motion; preserve face anatomy and consistent atlas anchors/scale.
- Use actual windowed rendering for visual evidence. Headless mode is for import, logic tests and packaging, not visual acceptance.
- Verify affected behavior before delivery. A simulation is not a completed player experience.
- Keep licenses/source links for every added asset. Never commit credentials, caches, personal machine paths or internal conversations.

## Shared development memory
After every change or review, add a timestamped entry under docs/dev-log/YYYYMMDDTHHMMSS_short-name.md with author/agent identity, files, reason, checks, evidence and remaining work. Update docs/STATUS.md and CHANGELOG.md as appropriate. Use Git commits for version history; do not rewrite previous authors' records. Mark untested claims clearly. Human/AI authors follow the same rule.
