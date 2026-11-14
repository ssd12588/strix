package render

import (
	"strconv"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// ---------------------------------------------------------------------------
// Coverage ledger (record_coverage / update_coverage / list_coverage)
// ---------------------------------------------------------------------------

// coverageOutcomes maps a ledger outcome to its marker and color. A cleared
// surface and an unresolved one must not look alike at a glance: the whole
// point of the ledger is that a reader can see which surfaces are still open.
var coverageOutcomes = map[string]struct {
	marker string
	label  string
	color  lipgloss.Color
}{
	"已回報":        {"!", "已回報", SevHigh},
	"no_issue_found":  {"✓", "未發現問題", Green},
	"ruled_out":       {"✓", "已排除", Mint},
	"not_applicable":  {"–", "不適用", Slate},
	"needs_follow_up": {"?", "需要後續追蹤", AmberY},
}

func coverageOutcome(outcome string) (string, string, lipgloss.Color) {
	if meta, ok := coverageOutcomes[strings.TrimSpace(strings.ToLower(outcome))]; ok {
		return meta.marker, meta.label, meta.color
	}
	if outcome == "" {
		return "·", "", Gray
	}
	return "·", strings.ReplaceAll(outcome, "_", " "), Gray
}

var coverageTitles = map[string]struct {
	title   string
	loading string
	errMsg  string
}{
	"record_coverage": {"已記錄涵蓋範圍", "記錄中...", "記錄涵蓋範圍失敗"},
	"update_coverage": {"已更新涵蓋範圍", "更新中...", "更新涵蓋範圍失敗"},
	"list_coverage":   {"涵蓋範圍", "載入中...", "無法列出涵蓋範圍"},
}

func renderCoverage(name string, args map[string]any, result any) string {
	meta := coverageTitles[name]
	var b strings.Builder
	b.WriteString("▣ " + Bold(Cyan).Render(meta.title))

	if s, ok := result.(string); ok && strings.TrimSpace(s) != "" {
		b.WriteString("\n  " + Dim().Render(strings.TrimSpace(s)))
		return b.String()
	}
	m, ok := result.(map[string]any)
	if !ok {
		coverageArgsPreview(&b, name, args)
		b.WriteString("\n  " + Dim().Render(meta.loading))
		return b.String()
	}
	if !truthy(m["success"]) {
		coverageArgsPreview(&b, name, args)
		errMsg := StringValue(m["error"])
		if errMsg == "" {
			errMsg = meta.errMsg
		}
		b.WriteString("\n  " + Col(Red).Render(errMsg))
		return b.String()
	}

	switch name {
	case "list_coverage":
		coverageListBody(&b, m)
	case "update_coverage":
		marker, label, color := coverageOutcome(StringValue(m["outcome"]))
		_, previous, previousColor := coverageOutcome(StringValue(m["previous_outcome"]))
		b.WriteString("\n  " + Col(color).Render(marker) + " " + coverageSubject(args, m))
		if previous != "" {
			b.WriteString("\n    " + Col(previousColor).Render(previous) +
				Dim().Render(" → ") + Col(color).Render(label))
		} else {
			b.WriteString("\n    " + Col(color).Render(label))
		}
		coverageEvidence(&b, StringValue(args["evidence"]))
	default:
		marker, label, color := coverageOutcome(StringValue(m["outcome"]))
		b.WriteString("\n  " + Col(color).Render(marker) + " " + coverageSubject(args, m))
		b.WriteString("\n    " + Col(color).Render(label))
		coverageEvidence(&b, StringValue(args["evidence"]))
	}
	return b.String()
}

// coverageSubject names the surface being recorded, falling back to the entry
// id when only the id is known (an update carries no surface in its args).
func coverageSubject(args map[string]any, result map[string]any) string {
	surface := strings.TrimSpace(StringValue(args["surface"]))
	risk := strings.TrimSpace(StringValue(args["risk_area"]))
	switch {
	case surface != "" && risk != "":
		return surface + Dim().Render(" · "+risk)
	case surface != "":
		return surface
	case risk != "":
		return risk
	}
	if id := StringValue(result["entry_id"]); id != "" {
		return Dim().Render("項目 " + id)
	}
	return Dim().Render("(unnamed surface)")
}

func coverageEvidence(b *strings.Builder, evidence string) {
	if strings.TrimSpace(evidence) != "" {
		b.WriteString("\n    " + Dim().Render(psanitize(strings.TrimSpace(evidence), 160)))
	}
}

func coverageArgsPreview(b *strings.Builder, name string, args map[string]any) {
	if name == "list_coverage" {
		return
	}
	if subject := coverageSubject(args, map[string]any{}); subject != "" {
		b.WriteString("\n  " + subject)
	}
}

func coverageListBody(b *strings.Builder, result map[string]any) {
	entries, _ := result["entries"].([]any)
	total, _ := NumericValue(result["total_count"])
	if len(entries) == 0 {
		if int(total) == 0 {
			b.WriteString("\n  " + Dim().Render("尚未記錄任何介面"))
		} else {
			b.WriteString("\n  " + Dim().Render("沒有符合此篩選條件的介面"))
		}
		return
	}

	if counts, ok := result["outcome_counts"].(map[string]any); ok && len(counts) > 0 {
		var parts []string
		for _, outcome := range []string{
			"已回報", "no_issue_found", "ruled_out", "not_applicable", "needs_follow_up",
		} {
			count, ok := NumericValue(counts[outcome])
			if !ok || count == 0 {
				continue
			}
			_, label, color := coverageOutcome(outcome)
			parts = append(parts, Col(color).Render(label+": "+strconv.Itoa(int(count))))
		}
		if len(parts) > 0 {
			b.WriteString("\n  " + strings.Join(parts, Dim().Render("  ")))
		}
	}

	for _, e := range entries {
		entry, _ := e.(map[string]any)
		marker, label, color := coverageOutcome(StringValue(entry["outcome"]))
		surface := strings.TrimSpace(StringValue(entry["surface"]))
		if surface == "" {
			surface = "(unnamed surface)"
		}
		b.WriteString("\n  " + Col(color).Render(marker) + " " + surface)
		if risk := strings.TrimSpace(StringValue(entry["risk_area"])); risk != "" {
			b.WriteString(Dim().Render(" · " + risk))
		}
		b.WriteString("\n    " + Col(color).Render(label))
		// A row that moved states carries its own history; showing it keeps a
		// closed surface from reading as one that was never in question.
		if previous, ok := entry["previous_outcomes"].([]any); ok && len(previous) > 0 {
			var was []string
			for _, p := range previous {
				if _, label, _ := coverageOutcome(StringValue(p)); label != "" {
					was = append(was, label)
				}
			}
			if len(was) > 0 {
				b.WriteString(Dim().Render("（原為 " + strings.Join(was, " → ") + "）"))
			}
		}
		// Whose row this is matters for reconciliation: an agent needs to see
		// at a glance which surfaces it owns and which came from a sibling.
		if truthy(entry["by_you"]) {
			b.WriteString(Dim().Render(" · you"))
		} else if who := strings.TrimSpace(StringValue(entry["agent_name"])); who != "" {
			b.WriteString(Dim().Render(" · " + who))
		}
		coverageEvidence(b, StringValue(entry["evidence"]))
	}
}
