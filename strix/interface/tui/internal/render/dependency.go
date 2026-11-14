package render

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

func renderDependencyReport(args map[string]any, result any) string {
	resultMap, _ := result.(map[string]any)
	// Unsuccessful / not-persisted variants.
	if resultMap != nil {
		success, hasSuccess := resultMap["success"].(bool)
		warning := StringValue(resultMap["warning"])
		if (hasSuccess && !success) || warning != "" {
			return renderDependencyUnsuccessful(args, resultMap)
		}
	}
	var b strings.Builder
	b.WriteString("📦 " + Bold(ReportHdr).Render("相依性（SCA）報告"))
	field := func(label, value string) {
		if value != "" {
			b.WriteString("\n\n" + Bold(Field).Render(label+": ") + value)
		}
	}
	title := StringValue(args["title"])
	field("Title", title)
	if sev := StringValue(resultMap["severity"]); sev != "" {
		b.WriteString("\n\n" + Bold(Field).Render("嚴重度: ") +
			lipgloss.NewStyle().Bold(true).Foreground(SeverityColor(sev)).Render(strings.ToUpper(sev)))
	}
	if score, ok := NumericValue(args["advisory_cvss"]); ok {
		b.WriteString("\n\n" + Bold(Field).Render("公告 CVSS: ") +
			lipgloss.NewStyle().Bold(true).Foreground(CVSSColor(score)).Render(StringValue(args["advisory_cvss"])))
	}
	field("CVE", StringValue(args["cve"]))
	field("CWE", StringValue(args["cwe"]))
	if pkg := StringValue(args["package_name"]); pkg != "" {
		b.WriteString("\n\n" + Bold(Field).Render("套件: ") + Bold(InfoBlue).Render(pkg))
		if eco := StringValue(args["package_ecosystem"]); eco != "" {
			b.WriteString(Dim().Render(" (" + eco + ")"))
		}
	}
	if inst := StringValue(args["installed_version"]); inst != "" {
		b.WriteString("\n\n" + Bold(Field).Render("已安裝版本: ") + Col(Red).Render(inst))
		if fixed := StringValue(args["fixed_version"]); fixed != "" {
			b.WriteString(Dim().Render("  →  ") + Bold(Field).Render("修正版本: ") + Col(Green).Render(fixed))
		}
	}
	field("修正難度", StringValue(args["fix_effort"]))
	field("Target", StringValue(args["target"]))
	section := func(label, value string) {
		if value != "" {
			b.WriteString("\n\n" + Bold(Field).Render(label) + "\n" + renderAssistantMarkdown(value))
		}
	}
	section("說明", StringValue(args["description"]))
	section("影響", StringValue(args["impact"]))
	section("技術分析", StringValue(args["technical_analysis"]))
	if reach := StringValue(args["reachability"]); reach != "" && reach != "unknown" {
		b.WriteString("\n\n" + Bold(Field).Render("使用證據: ") + reach)
		if ev := StringValue(args["reachability_evidence"]); ev != "" {
			b.WriteString("\n" + ev)
		}
	}
	section("Assumptions", StringValue(args["assumptions"]))
	section("修補建議", StringValue(args["remediation_steps"]))
	if title == "" {
		b.WriteString("\n  " + Dim().Render("正在建立相依性報告..."))
	}
	return "\n\n" + b.String() + "\n\n"
}

func renderDependencyUnsuccessful(args, result map[string]any) string {
	var b strings.Builder
	b.WriteString("📦 " + Bold(ReportHdr).Render("相依性（SCA）報告"))
	if title := StringValue(args["title"]); title != "" {
		b.WriteString("\n\n" + Bold(Field).Render("標題: ") + title)
	}
	success, hasSuccess := result["success"].(bool)
	var label, detail string
	var style lipgloss.Style
	if hasSuccess && !success {
		detail = StringValue(result["error"])
		if errs, ok := result["errors"].([]any); ok && len(errs) > 0 {
			var parts []string
			for _, e := range errs {
				parts = append(parts, StringValue(e))
			}
			detail = strings.Join(parts, "; ")
		}
		label, style = "✗ Not created: ", Bold(SevCrit)
		if detail == "" {
			detail = "報告未建立。"
		}
	} else {
		detail = StringValue(result["warning"])
		label, style = "⚠ Not persisted: ", Bold(SevMed)
		if detail == "" {
			detail = "報告無法保存。"
		}
	}
	b.WriteString("\n\n" + style.Render(label) + detail)
	return "\n\n" + b.String() + "\n\n"
}
