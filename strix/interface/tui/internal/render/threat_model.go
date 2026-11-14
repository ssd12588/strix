package render

import (
	"strconv"
	"strings"
)

// ---------------------------------------------------------------------------
// Threat model (get_threat_model / save_threat_model / amend_threat_model)
// ---------------------------------------------------------------------------

var threatModelTitles = map[string]struct {
	title   string
	loading string
	errMsg  string
}{
	"get_threat_model":   {"威脅模型", "載入中...", "無法讀取威脅模型"},
	"save_threat_model":  {"威脅模型已儲存", "儲存中...", "儲存威脅模型失敗"},
	"amend_threat_model": {"威脅模型已修訂", "修訂中...", "修訂威脅模型失敗"},
}

func renderThreatModel(name string, args map[string]any, result any) string {
	meta := threatModelTitles[name]
	var b strings.Builder
	b.WriteString("⌖ " + Bold(InfoBlue).Render(meta.title))
	if target := strings.TrimSpace(StringValue(args["target"])); target != "" {
		b.WriteString(Dim().Render(" " + target))
	}

	if s, ok := result.(string); ok && strings.TrimSpace(s) != "" {
		b.WriteString("\n  " + Dim().Render(strings.TrimSpace(s)))
		return b.String()
	}
	m, ok := result.(map[string]any)
	if !ok {
		b.WriteString("\n  " + Dim().Render(meta.loading))
		return b.String()
	}
	if !truthy(m["success"]) {
		errMsg := StringValue(m["error"])
		if errMsg == "" {
			errMsg = meta.errMsg
		}
		b.WriteString("\n  " + Col(Red).Render(errMsg))
		return b.String()
	}

	switch name {
	case "get_threat_model":
		threatModelReadBody(&b, m)
	case "amend_threat_model":
		b.WriteString("\n  " + Col(Green).Render("✓ amendment recorded"))
		if count, ok := NumericValue(m["amendment_count"]); ok {
			b.WriteString(Dim().Render(" (" + strconv.Itoa(int(count)) + " total)"))
		}
		threatModelBody(&b, StringValue(args["addendum"]))
	default:
		b.WriteString("\n  " + Col(Green).Render("✓ saved"))
		// Saving folds amendments away, so the count that vanished is worth
		// stating: it is the one destructive thing this tool does.
		if cleared, ok := NumericValue(m["amendments_cleared"]); ok && cleared > 0 {
			b.WriteString("\n  " + Col(AmberY).Render("⚠ cleared "+
				strconv.Itoa(int(cleared))+" amendment(s)"))
		}
		threatModelBody(&b, StringValue(args["content"]))
	}
	return b.String()
}

func threatModelReadBody(b *strings.Builder, result map[string]any) {
	if !truthy(result["found"]) {
		b.WriteString("\n  " + Dim().Render("此目標尚未推導出威脅模型"))
		return
	}
	if amendments, ok := result["amendments"].([]any); ok && len(amendments) > 0 {
		b.WriteString("\n  " + Col(Gold).Render("+ "+strconv.Itoa(len(amendments))+
			" amendment(s)") + Dim().Render(" — later statements win"))
		for _, a := range amendments {
			amendment, _ := a.(map[string]any)
			who := strings.TrimSpace(StringValue(amendment["agent_name"]))
			if who == "" {
				who = "未知代理"
			}
			b.WriteString("\n    - " + Dim().Render(who+": ") +
				psanitize(strings.TrimSpace(StringValue(amendment["content"])), 120))
		}
	}
	threatModelBody(b, StringValue(result["content"]))
}

// threatModelBody previews the document. The full text is a page or more, so
// only its section headings and opening line are shown here; the trace can be
// expanded for the rest.
func threatModelBody(b *strings.Builder, content string) {
	content = strings.TrimSpace(content)
	if content == "" {
		return
	}
	var headings []string
	summary := ""
	for _, line := range strings.Split(content, "\n") {
		line = strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(line, "#"):
			headings = append(headings, strings.TrimSpace(strings.TrimLeft(line, "# ")))
		case summary == "" && line != "":
			summary = line
		}
	}
	if summary != "" {
		b.WriteString("\n  " + Dim().Render(psanitize(summary, 160)))
	}
	if len(headings) > 0 {
		if len(headings) > 8 {
			headings = headings[:8]
		}
		b.WriteString("\n  " + Dim().Render(strings.Join(headings, " · ")))
	}
}
