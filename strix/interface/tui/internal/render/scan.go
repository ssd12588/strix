package render

import (
	"strings"
)

// ---------------------------------------------------------------------------
// Finish scan (finish_renderer.py)
// ---------------------------------------------------------------------------

func renderFinishScan(args map[string]any) string {
	var b strings.Builder
	b.WriteString(Col(Green).Render("◆ ") + Bold(Green).Render("滲透測試完成"))
	section := func(label, value string) {
		if value != "" {
			b.WriteString("\n\n" + Bold(Field).Render(label) + "\n" + renderAssistantMarkdown(value))
		}
	}
	es := StringValue(args["executive_summary"])
	me := StringValue(args["methodology"])
	ta := StringValue(args["technical_analysis"])
	re := StringValue(args["recommendations"])
	section("執行摘要", es)
	section("Methodology", me)
	section("技術分析", ta)
	section("Recommendations", re)
	if es == "" && me == "" && ta == "" && re == "" {
		b.WriteString("\n  " + Dim().Render("正在產生最終報告..."))
	}
	return "\n\n" + b.String() + "\n\n"
}
