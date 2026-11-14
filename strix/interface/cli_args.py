"""Command-line argument parsing for the ``strix`` scan entrypoint."""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any, NoReturn

from strix.config import apply_config_override
from strix.config.settings import DEFAULT_MAX_TURNS
from strix.core.paths import RUNS_DIR_NAME, run_dir_for, runtime_state_dir
from strix.interface.scan_setup import attach_workspace_mount, build_targets_info
from strix.interface.update_check import self_update
from strix.interface.utils import (
    check_mountable_dir,
    collect_local_sources,
    resolve_workspace_files,
    validate_config_file,
)
from strix.report.runs import list_run_summaries


# Severities ``--fail-on`` accepts, most severe first.
FAIL_ON_SEVERITIES = ("critical", "high", "medium", "low", "info")

# 繁體中文版的 argparse 內建標題與訊息對照表。
_HELP_SECTIONS = {
    "positional arguments": "位置參數",
    "options": "選項",
    "optional arguments": "選項",
}

_ARGPARSE_INLINE = (
    ("unrecognized arguments: ", "無法辨識的參數: "),
    ("the following arguments are required: ", "下列參數為必填: "),
    ("invalid choice: ", "無效的選擇: "),
    ("ambiguous option: ", "選項不明確: "),
    ("expected one argument", "需要一個值"),
    ("expected at most one argument", "最多只能有一個值"),
    ("expected at least one argument", "至少需要一個值"),
    ("ignored explicit argument ", "已忽略明確指定的參數值 "),
)

# argparse 的 "invalid choice: 'x' (choose from 'a', 'b')" 尾段。
_CHOOSE_FROM_RE = re.compile(r"\(choose from ([^)]*)\)")


def _translate_argparse(message: str) -> str:
    """Translate the argparse-generated part of an error message.

    argparse formats the message before calling ``error()``, so the translation
    matches known fragments and leaves user-supplied text untouched.
    """
    translated = message
    for source, replacement in _ARGPARSE_INLINE:
        translated = translated.replace(source, replacement)
    if translated.startswith("argument "):
        translated = "參數 " + translated[len("argument ") :]
    return _CHOOSE_FROM_RE.sub(r"（可選: \1）", translated)


class _TraditionalChineseHelpFormatter(argparse.RawDescriptionHelpFormatter):
    """Help formatter that renders argparse's built-in headings in Chinese."""

    def add_usage(
        self,
        usage: str | None,
        actions: list[argparse.Action],
        groups: Any,  # 沿用 argparse 自身的未標註簽名
        prefix: str | None = None,
    ) -> str:
        return super().add_usage(usage, actions, groups, prefix=prefix or "用法: ")

    def start_section(self, heading: str | None) -> None:
        super().start_section(_HELP_SECTIONS.get(heading or "", heading))


class _TraditionalChineseArgumentParser(argparse.ArgumentParser):
    """Argument parser that reports errors with a Chinese prefix."""

    def error(self, message: str) -> NoReturn:
        self.print_usage(sys.stderr)
        self.exit(2, f"{self.prog}: 錯誤: {_translate_argparse(message)}\n")


def get_version() -> str:
    try:
        from importlib.metadata import version

        return version("strix-agent")
    except Exception:
        return "unknown"


def _positive_budget(value: str) -> float:
    try:
        budget = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"無效的浮點數: {value!r}") from exc
    import math

    if not math.isfinite(budget) or budget <= 0:
        raise argparse.ArgumentTypeError("必須是大於 0 的有限數字")
    return budget


def _positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"無效的整數: {value!r}") from exc
    if parsed <= 0:
        raise argparse.ArgumentTypeError("必須是大於 0 的整數")
    return parsed


def parse_arguments() -> argparse.Namespace:
    parser = _TraditionalChineseArgumentParser(
        prog="strix",
        description="Strix 多代理網路安全滲透測試工具",
        formatter_class=_TraditionalChineseHelpFormatter,
        add_help=False,
        epilog="""
範例:
  # 網站應用程式滲透測試
  strix --target https://example.com

  # GitHub 儲存庫分析
  strix --target https://github.com/user/repo
  strix --target git@github.com:user/repo.git

  # 本機程式碼分析
  strix --target ./my-project

  # API 規格測試（OpenAPI/Swagger 檔案，或 Postman collection 匯出檔）
  strix --target ./openapi.yaml --target https://api.example.com
  strix --target ./collection.postman_collection.json

  # 以 id 即時取得 Postman collection（需 POSTMAN_API_KEY）；可選擇指定 environment
  strix --target postman://<collection-uuid> --target https://api.example.com
  strix --target "postman://<collection-uuid>?env=<environment-uuid>"

  # 網域滲透測試
  strix --target example.com

  # IP 位址滲透測試
  strix --target 192.168.1.42

  # 多個目標（例如白箱測試：同時提供原始碼與已部署的應用程式）
  strix --target https://github.com/user/repo --target https://example.com
  strix --target ./my-project --target https://staging.example.com --target https://prod.example.com

  # 從檔案讀取目標，每行一個（略過空行與註解行）
  strix --target-list ./targets.txt

  # 自訂指令（直接寫在命令列）
  strix --target example.com --instruction "專注於認證相關漏洞"

  # 自訂指令（從檔案讀取）
  strix --target example.com --instruction-file ./instructions.txt
  strix --target https://app.com --instruction-file /path/to/detailed_instructions.md

  # 額外放入沙箱工作區的檔案
  strix --target ./my-project --workspace-file ./wordlist.txt
  strix --target https://app.com --workspace-file ./openapi.yaml:specs/openapi.yaml

Strix 雲端:
  strix cloud login
  strix cloud scans start --source . --yes --wait
  strix cloud                      # 列出所有雲端資源

  在 Strix Cloud 執行滲透測試      https://app.strix.ai
  試用 Strix Enterprise            https://strix.ai/demo
        """,
    )

    parser.add_argument(
        "-h",
        "--help",
        action="help",
        help="顯示此說明並結束",
    )

    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"strix {get_version()}",
        help="顯示版本編號並結束",
    )

    parser.add_argument(
        "--update",
        action="store_true",
        help="將 strix 更新到最新版本後結束。獨立二進位安裝會自動更新；"
        "pip/pipx/uv 安裝則印出對應的升級指令。",
    )

    parser.add_argument(
        "-t",
        "--target",
        type=str,
        action="append",
        help="要測試的目標：URL、儲存庫、本機目錄路徑、網域名稱、IP 位址、"
        "API 規格檔（OpenAPI/Swagger .json/.yaml 或 Postman collection 匯出檔），或"
        "以 id 指定的 Postman collection（postman://<collection-uuid>[?env=<environment-uuid>]，"
        "需 POSTMAN_API_KEY）。本機目錄會以可寫入方式掛載進沙箱。"
        "可重複指定以進行多目標掃描。"
        "全新掃描必須提供 --target 或 --target-list。",
    )
    parser.add_argument(
        "--target-list",
        type=str,
        action="append",
        metavar="PATH",
        help="目標檔案路徑，每行一個目標（略過空行與註解行）。可重複指定，並可與 --target 併用。",
    )
    parser.add_argument(
        "--instruction",
        type=str,
        help="滲透測試的自訂指令。可以是："
        "要特別關注的漏洞類型（例如 'Focus on IDOR and XSS'）、"
        "測試手法（例如 'Perform thorough authentication testing'）、"
        "測試帳號密碼（例如 'Use the following credentials to access the app: "
        "admin:password123'），"
        "或感興趣的範圍（例如 'Check login API endpoint for security issues'）。",
    )

    parser.add_argument(
        "--instruction-file",
        type=str,
        help="包含詳細自訂指令的檔案路徑。"
        "當指令較長或較複雜並已存成檔案時使用"
        "（例如 '--instruction-file ./detailed_instructions.txt'）。",
    )

    parser.add_argument(
        "--workspace-file",
        type=str,
        action="append",
        metavar="PATH[:DEST]",
        help="在掃描開始前，把本機檔案放進沙箱工作區，例如字典檔、API 規格或筆記。"
        "需要多個檔案時可重複指定。DEST 是 /workspace 內的路徑，預設為原檔名"
        "（例如 '--workspace-file ./wordlist.txt:lists/wordlist.txt'）。Strix 會把檔案"
        "複製到沙箱內、位於所有目標目錄之外的位置。代理可以編輯該副本，"
        "本機上的原檔案不會被更動。",
    )

    parser.add_argument(
        "-n",
        "--non-interactive",
        action="store_true",
        help=("以非互動模式執行（不開啟 TUI，完成後直接結束）。預設為開啟 TUI 的互動模式。"),
    )

    parser.add_argument(
        "--fail-on",
        dest="fail_on",
        type=str.lower,
        choices=FAIL_ON_SEVERITIES,
        default=None,
        metavar="SEVERITY",
        help=(
            "僅限無介面（headless）模式：只有當某個發現達到或高於此嚴重度時才以狀態碼 2 結束"
            "（critical、high、medium、low、info）。較輕微的發現仍會寫入所有報告檔案。"
            "無法辨識的嚴重度一律視為達到門檻。"
            "預設：任何發現都會以狀態碼 2 結束。"
        ),
    )

    parser.add_argument(
        "-m",
        "--scan-mode",
        type=str,
        choices=["quick", "standard", "deep"],
        default="deep",
        help=(
            "掃描模式："
            "'quick' 用於快速的 CI/CD 檢查，"
            "'standard' 用於例行測試，"
            "'deep' 用於徹底的安全檢視（預設）。"
            "預設值：deep。"
        ),
    )

    parser.add_argument(
        "--scope-mode",
        type=str,
        choices=["auto", "diff", "full"],
        default="auto",
        help=(
            "程式碼目標的範圍模式："
            "'auto' 在 CI／無介面執行時啟用 PR diff 範圍，"
            "'diff' 強制只掃描有變更的檔案，"
            "'full' 停用 diff 範圍。"
        ),
    )

    parser.add_argument(
        "--diff-base",
        type=str,
        help=("用來比對的目標分支或 commit（例如 origin/main）。預設為儲存庫的預設分支。"),
    )

    parser.add_argument(
        "--config",
        type=str,
        help="自訂設定檔（JSON）路徑，用來取代 ~/.strix/cli-config.json",
    )

    parser.add_argument(
        "--mcp-config",
        type=str,
        metavar="PATH",
        help="MCP 伺服器的 JSON 設定檔路徑，用來取代 ~/.strix/mcp-servers.json。",
    )

    parser.add_argument(
        "--mcp-server",
        dest="mcp_server",
        action="append",
        metavar="NAME",
        help="本次執行只使用這個 MCP 連線（以設定的名稱為準，可重複指定）。"
        "其他已設定的連線都會被略過。",
    )

    parser.add_argument(
        "--mcp-exclude",
        dest="mcp_exclude",
        action="append",
        metavar="NAME",
        help="本次執行略過這個 MCP 連線（以設定的名稱為準，可重複指定）。",
    )

    parser.add_argument(
        "--max-budget",
        "--max-budget-usd",
        dest="max_budget_usd",
        metavar="USD",
        type=_positive_budget,
        default=None,
        help=(
            "LLM 花費上限（美元，需大於 0）。達到此上限時掃描會乾淨地停止。"
            "接近上限時會對所有代理發出分級的收尾警告。"
        ),
    )

    parser.add_argument(
        "--max-turns",
        dest="max_turns",
        metavar="N",
        type=_positive_int,
        default=DEFAULT_MAX_TURNS,
        help=(
            "每個代理的最大回合數（大於 0，預設 %(default)s）。代理達到此上限時會被強制停止，"
            "接近上限時會收到分級的收尾警告。"
        ),
    )

    parser.add_argument(
        "-r",
        "--resume",
        type=str,
        nargs="?",
        const="",
        metavar="RUN_NAME",
        help=(
            "以執行名稱恢復先前的掃描（./strix_runs/ 下的目錄）。"
            "會接續根代理與每個未終止子代理的完整 LLM 對話歷史"
            "及代理拓撲，並跳過重新產生執行名稱。"
            "不給名稱時，會開啟先前執行的選擇畫面。"
        ),
    )

    args = parser.parse_args()
    # Startup-resolved state lives alongside the parsed flags. The full schema
    # is established here so downstream code reads attributes directly.
    args.needs_setup = False
    args.resume_picker = False
    args.targets_info = []
    args.local_sources = []
    args.diff_scope = {"active": False}
    args.run_name = None

    if args.config:
        apply_config_override(validate_config_file(args.config))

    if args.mcp_config:
        mcp_config_path = Path(args.mcp_config).expanduser()
        if not mcp_config_path.is_file():
            parser.error(f"找不到 --mcp-config 指定的檔案: {args.mcp_config}")
        # The MCP loader reads this env var as its config-path override, so
        # setting it here makes the flag win over the default location.
        os.environ["STRIX_MCP_CONFIG"] = str(mcp_config_path)

    # The MCP loader reads these as its per-run include/exclude selection.
    if args.mcp_server:
        os.environ["STRIX_MCP_ONLY"] = ",".join(args.mcp_server)
    if args.mcp_exclude:
        os.environ["STRIX_MCP_EXCLUDE"] = ",".join(args.mcp_exclude)

    if args.update:
        sys.exit(0 if self_update() else 1)

    if args.fail_on and not args.non_interactive and terminal_attached():
        # Without a terminal main() switches to headless anyway, so the
        # flag is only out of place when the TUI would actually open.
        parser.error("--fail-on 僅適用於無介面執行；請加上 -n/--non-interactive。")

    if args.instruction and args.instruction_file:
        parser.error("不能同時指定 --instruction 與 --instruction-file，請擇一使用。")

    if args.instruction_file:
        instruction_path = Path(args.instruction_file)
        try:
            with instruction_path.open(encoding="utf-8") as f:
                args.instruction = f.read().strip()
                if not args.instruction:
                    parser.error(f"指令檔案 '{instruction_path}' 內容為空")
        except Exception as e:
            parser.error(f"讀取指令檔案 '{instruction_path}' 失敗: {e}")

    try:
        args.workspace_files = resolve_workspace_files(getattr(args, "workspace_file", None))
    except ValueError as error:
        parser.error(f"--workspace-file: {error}")

    args.user_explicit_instruction = args.instruction if args.resume is not None else None
    # What the user actually asked for, kept apart from args.instruction because
    # prepare_run prepends the diff-scope preamble to that. This is the text the
    # transcript shows as their opening message.
    args.user_instruction = args.instruction or None

    if args.resume is not None:
        if args.target or args.target_list:
            parser.error(
                "不能同時使用 --resume 與 --target/--target-list。"
                "--resume 會從上次中斷處接續，包含原本的目標清單。"
            )
        if not args.resume.strip():
            # A bare --resume: main() opens the inline picker of prior runs
            # before anything launches; headless has nobody to pick, so it
            # lists them.
            args.resume = None
            args.resume_picker = True
            if args.non_interactive:
                parser.error(resume_run_list_message("--resume 在無介面模式下需要指定執行名稱。"))
            if not list_run_summaries():
                parser.error(f"--resume: ./{RUNS_DIR_NAME} 中沒有可恢復的執行記錄")
            return args
        try:
            load_resume_state(args)
        except ResumeError as exc:
            parser.error(str(exc))
    else:
        if not args.target and not args.target_list:
            if args.non_interactive:
                parser.error(
                    "缺少必要參數: -t/--target 或 --target-list "
                    "（或使用 --resume <run_name> 接續先前的掃描）"
                )
            # Interactive launch with no target: open the normal TUI on its
            # start screen, where the user gives a target or a bare prompt
            # before the scan starts.
            args.needs_setup = True
            return args

        try:
            build_targets_info(args)
        except ValueError as e:
            parser.error(str(e))

    return args


def terminal_attached() -> bool:
    """Whether the TUI can take over the terminal: a tty on both ends, not dumb."""
    if os.environ.get("TERM", "").strip().lower() == "dumb":
        return False
    return all(hasattr(stream, "isatty") and stream.isatty() for stream in (sys.stdin, sys.stdout))


class ResumeError(ValueError):
    """A prior run cannot be resumed as recorded; the message names why."""


def resume_run_list_message(lead: str) -> str:
    """``lead`` followed by the runs that ``--resume <name>`` would accept."""
    runs = list_run_summaries()
    if not runs:
        return f"{lead} ./{RUNS_DIR_NAME} 中沒有任何執行記錄。"
    name_width = max(len(run.run_name) for run in runs)
    status_width = max(len(run.status) for run in runs)
    lines = [f"{lead} ./{RUNS_DIR_NAME} 中的執行記錄:"]
    lines.extend(
        f"  {run.run_name:<{name_width}}  {run.status:<{status_width}}  "
        f"{run.started_at[:19]:<19}  {run.target}".rstrip()
        for run in runs
    )
    return "\n".join(lines)


def load_resume_state(args: argparse.Namespace) -> None:
    """Populate ``args.targets_info`` and friends from a prior run's run.json.

    Raises :class:`ResumeError` when the run is missing, unreadable, or its
    recorded workspace is gone.
    """
    from strix.report.writer import read_run_record

    run_dir = run_dir_for(args.resume)
    state_path = run_dir / "run.json"
    if not state_path.exists():
        raise ResumeError(
            f"--resume {args.resume}: 找不到此執行 （缺少 {state_path}；移除 --resume 可重新開始）"
        )
    try:
        state = read_run_record(run_dir)
    except (RuntimeError, TypeError) as exc:
        raise ResumeError(f"--resume {args.resume}: run.json 無法讀取: {exc}") from exc

    args.targets_info = state.get("targets_info") or []
    # A target-less run has no targets_info at all. It is driven by its
    # instruction, over a mounted working directory or over nothing when the
    # mount was declined, so either of those is enough to resume it.
    workspace_mount = state.get("workspace_mount") or None
    if not args.targets_info and not workspace_mount and not state.get("user_instruction"):
        raise ResumeError(f"--resume {args.resume}: run.json 內沒有 targets_info")

    for target in args.targets_info:
        if not isinstance(target, dict):
            continue
        details = target.get("details") or {}
        if target.get("type") == "local_code" and details.get("target_path"):
            try:
                check_mountable_dir(Path(details["target_path"]).expanduser())
            except ValueError as exc:
                raise ResumeError(f"--resume {args.resume}: {exc}") from exc
            continue
        if target.get("type") != "repository":
            continue
        cloned = details.get("cloned_repo_path")
        if not cloned:
            continue
        if not Path(cloned).expanduser().exists():
            raise ResumeError(
                f"--resume {args.resume}: 找不到複製的儲存庫 {cloned}。"
                f"它在兩次執行之間被刪除了。請指定新的 --run-name 重新複製，"
                f"或在恢復前把該目錄還原。"
            )

    if args.instruction is None:
        args.instruction = state.get("instruction")
    if not getattr(args, "user_instruction", None):
        args.user_instruction = state.get("user_instruction") or None
    args.local_sources = collect_local_sources(args.targets_info)
    # Remount the workspace the run was started with. The user already confirmed
    # this directory, so the target mount guard does not apply to it; it only has
    # to still be there.
    args.workspace_mount = workspace_mount

    # Replace the workspace files the run started with, unless this resume names
    # its own. The persisted record is revalidated like a fresh flag, so an
    # edited run.json cannot widen what a resume places. A file deleted between
    # runs is dropped rather than fatal: it is context for the agent, not scope.
    if not getattr(args, "workspace_files", None):
        restored = [
            f"{source_path}:{workspace_path}"
            for workspace_file in state.get("workspace_files") or []
            if isinstance(workspace_file, dict)
            and (source_path := Path(str(workspace_file.get("source_path") or ""))).is_file()
            and (workspace_path := str(workspace_file.get("workspace_path") or ""))
        ]
        try:
            args.workspace_files = resolve_workspace_files(restored)
        except ValueError as error:
            raise ResumeError(f"--resume {args.resume}: 工作區檔案無效: {error}") from error
    if workspace_mount:
        if not Path(workspace_mount).expanduser().is_dir():
            raise ResumeError(
                f"--resume {args.resume}: 工作目錄 {workspace_mount} "
                f"不存在。請在恢復前還原它，或改為全新的執行。"
            )
        attach_workspace_mount(args)
    if state.get("diff_scope"):
        args.diff_scope = state.get("diff_scope")
    persisted_scan_mode = state.get("scan_mode")
    if persisted_scan_mode and args.scan_mode == "deep":
        args.scan_mode = persisted_scan_mode
    agents_path = runtime_state_dir(run_dir) / "agents.json"
    if not agents_path.exists():
        raise ResumeError(
            f"--resume {args.resume}: 缺少 {agents_path}。這次執行"
            f"已寫入紀錄，但從未產生第一份代理快照 —— "
            f"因此沒有可恢復的內容。請指定新的 --run-name，"
            f"或移除 --resume 以相同目標重新開始。"
        )
