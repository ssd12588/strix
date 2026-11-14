package render

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// ---------------------------------------------------------------------------
// Todos (todo_renderer.py)
// ---------------------------------------------------------------------------

var todoMarkers = map[string]string{"pending": "[ ]", "in_progress": "[~]", "done": "[•]"}

var todoTitles = map[string]struct {
	title   string
	color   lipgloss.Color
	loading string
	errMsg  string
}{
	"create_todo":       {"待辦事項", Lavender, "建立中...", "建立待辦事項失敗"},
	"list_todos":        {"Todos", Lavender, "載入中...", "無法列出待辦事項"},
	"update_todo":       {"待辦事項已更新", Lavender, "更新中...", "更新待辦事項失敗"},
	"mark_todo_done":    {"待辦事項已完成", Lavender, "標記完成中...", "標記待辦事項完成失敗"},
	"mark_todo_pending": {"待辦事項已重新開啟", AmberY, "重新開啟中...", "重新開啟待辦事項失敗"},
	"delete_todo":       {"待辦事項已移除", Slate, "移除中...", "移除待辦事項失敗"},
}

func renderTodo(name string, result any) string {
	meta := todoTitles[name]
	var b strings.Builder
	b.WriteString("📋 " + Bold(meta.color).Render(meta.title))
	if s, ok := result.(string); ok && strings.TrimSpace(s) != "" {
		b.WriteString("\n  " + Dim().Render(strings.TrimSpace(s)))
		return b.String()
	}
	if m, ok := result.(map[string]any); ok {
		if truthy(m["success"]) {
			formatTodoLines(&b, m)
		} else {
			errMsg := StringValue(m["error"])
			if errMsg == "" {
				errMsg = meta.errMsg
			}
			b.WriteString("\n  " + Col(Red).Render(errMsg))
		}
	} else {
		b.WriteString("\n  " + Dim().Render(meta.loading))
	}
	return b.String()
}

func formatTodoLines(b *strings.Builder, result map[string]any) {
	todos, ok := result["todos"].([]any)
	if !ok || len(todos) == 0 {
		b.WriteString("\n  " + Dim().Render("沒有待辦事項"))
		return
	}
	for _, t := range todos {
		todo, _ := t.(map[string]any)
		status := StringValue(todo["status"])
		marker := todoMarkers[status]
		if marker == "" {
			marker = todoMarkers["pending"]
		}
		title := strings.TrimSpace(StringValue(todo["title"]))
		if title == "" {
			title = "(untitled)"
		}
		b.WriteString("\n  " + marker + " ")
		switch status {
		case "done":
			b.WriteString(Dim().Strikethrough(true).Render(title))
		case "in_progress":
			b.WriteString(lipgloss.NewStyle().Italic(true).Render(title))
		default:
			b.WriteString(title)
		}
	}
}
