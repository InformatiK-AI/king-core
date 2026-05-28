#!/usr/bin/env bash
# hooks/a11y-check.sh — A11y Gate stub (M-28)
# Full implementation pending PostToolUse stdin format validation (see design.md#open-questions).
# Emits a visible WARN so users know the gate is inactive, not silently passing.
# castle-report will show a11y as status:"missing" (graceful degradation, correct).
echo "[King/A11y] WARN: a11y-check.sh is a stub — WCAG 2.2 AA gate not yet active. See design.md#open-questions." >&2
exit 0
