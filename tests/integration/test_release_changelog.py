"""Integration tests for src/changelog_formatter.py — Keep a Changelog generation."""
import pytest
from src.changelog_formatter import (
    parse_commits,
    format_changelog_section,
    COMMIT_TYPE_MAP,
    CATEGORY_ORDER,
)


class TestParseCommits:
    def test_feat_maps_to_added(self):
        lines = ["abc1234 feat: add api_version support"]
        result = parse_commits(lines)
        assert "Added" in result
        assert result["Added"] == ["add api_version support"]

    def test_fix_maps_to_fixed(self):
        lines = ["abc1234 fix: strip UTF-8 BOM from frontmatter"]
        result = parse_commits(lines)
        assert "Fixed" in result
        assert result["Fixed"] == ["strip UTF-8 BOM from frontmatter"]

    def test_security_maps_to_security(self):
        lines = ["abc1234 security: validate frontmatter before eval"]
        result = parse_commits(lines)
        assert "Security" in result
        assert result["Security"] == ["validate frontmatter before eval"]

    def test_deprecate_maps_to_deprecated(self):
        lines = ["abc1234 deprecate: old-param flag deprecated"]
        result = parse_commits(lines)
        assert "Deprecated" in result
        assert result["Deprecated"] == ["old-param flag deprecated"]

    def test_remove_maps_to_removed(self):
        lines = ["abc1234 remove: legacy compatibility shim"]
        result = parse_commits(lines)
        assert "Removed" in result
        assert result["Removed"] == ["legacy compatibility shim"]

    def test_refactor_maps_to_changed(self):
        lines = ["abc1234 refactor(audit): extract score logic"]
        result = parse_commits(lines)
        assert "Changed" in result
        assert result["Changed"] == ["extract score logic"]

    def test_chore_maps_to_changed(self):
        lines = ["abc1234 chore: update dependencies"]
        result = parse_commits(lines)
        assert "Changed" in result
        assert result["Changed"] == ["update dependencies"]

    def test_scope_stripped(self):
        lines = ["abc1234 feat(api): versioning"]
        result = parse_commits(lines)
        assert "Added" in result
        assert result["Added"] == ["versioning"]

    def test_breaking_exclamation_prefixes_description(self):
        lines = ["abc1234 feat!: redesign health score formula"]
        result = parse_commits(lines)
        items = result.get("Added", [])
        assert any("⚠️ BREAKING:" in item for item in items)

    def test_breaking_footer_in_body(self):
        lines = [
            "abc1234 refactor: rename compute_score to compute_health_score",
            "",
            "BREAKING CHANGE: all callers must update import",
        ]
        result = parse_commits(lines)
        items = result.get("Changed", [])
        assert any("⚠️ BREAKING:" in item for item in items)

    def test_empty_categories_omitted(self):
        lines = ["abc1234 fix: correct weight arithmetic"]
        result = parse_commits(lines)
        # Only Fixed should be present — no Added, Changed, etc.
        assert set(result.keys()) == {"Fixed"}

    def test_empty_input_returns_empty(self):
        assert parse_commits([]) == {}

    def test_unknown_type_maps_to_changed(self):
        lines = ["abc1234 unknowntype: some commit"]
        result = parse_commits(lines)
        assert "Changed" in result

    def test_gh_absent_no_crash(self):
        """Simulates gh-absent path: empty input returns {} without exception."""
        result = parse_commits([])
        assert result == {}

    def test_multi_commit_batch(self):
        lines = [
            "aaa0001 feat: add plugin registry",
            "bbb0002 fix: correct BOM stripping",
            "ccc0003 refactor: simplify audit loop",
            "ddd0004 security: sanitize frontmatter eval",
            "eee0005 remove: drop legacy v1 API",
        ]
        result = parse_commits(lines)
        assert "Added" in result
        assert "Fixed" in result
        assert "Changed" in result
        assert "Security" in result
        assert "Removed" in result
        assert len(result["Added"]) == 1
        assert len(result["Fixed"]) == 1


class TestFormatChangelogSection:
    def test_basic_section_format(self):
        categories = {"Added": ["new feature"], "Fixed": ["bug fix"]}
        output = format_changelog_section("2.0.0", "2026-05-28", categories)
        assert "## [2.0.0] — 2026-05-28" in output
        assert "### Added" in output
        assert "### Fixed" in output
        assert "- new feature" in output

    def test_format_section_heading(self):
        categories = {"Fixed": ["correct weight arithmetic"]}
        output = format_changelog_section("1.9.5", "2026-05-28", categories)
        assert output.startswith("## [1.9.5] — 2026-05-28")

    def test_empty_categories_omitted(self):
        categories = {"Fixed": ["fix something"]}
        output = format_changelog_section("1.0.0", "2026-01-01", categories)
        assert "### Added" not in output
        assert "### Fixed" in output

    def test_no_categories_renders_placeholder(self):
        output = format_changelog_section("1.0.0", "2026-01-01", {})
        assert "no changes logged" in output

    def test_none_categories_renders_placeholder(self):
        output = format_changelog_section("1.0.0", "2026-01-01", None)
        assert "no changes logged" in output

    def test_format_section_canonical_order(self):
        categories = {"Fixed": ["f"], "Added": ["a"], "Security": ["s"]}
        output = format_changelog_section("1.0.0", "2026-01-01", categories)
        added_pos = output.index("### Added")
        fixed_pos = output.index("### Fixed")
        security_pos = output.index("### Security")
        assert added_pos < fixed_pos < security_pos


class TestCommitTypeMapCompleteness:
    def test_all_spec_types_present(self):
        required = {"feat", "fix", "security", "deprecate", "remove"}
        assert required.issubset(COMMIT_TYPE_MAP.keys())

    def test_category_order_has_all_six(self):
        assert set(CATEGORY_ORDER) == {
            "Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"
        }
