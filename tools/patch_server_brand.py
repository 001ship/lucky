"""服务端品牌化补丁：登录账号名、启动横幅、MCP serverInfo、日志行。

只替换用户可见的品牌串，保留 Go module 路径、环境变量名（ARTEX_*）、
内部表名与文件名，避免破坏既有部署与配置。
"""

from pathlib import Path

ROOT = Path(r"C:\Users\111111\Desktop\999\lucky")

BANNER_OLD_START = "const banner = `"
BANNER_OLD_END = "`\n"

BANNER_NEW = """const banner = `
  ██╗     ██╗   ██╗ ██████╗██╗  ██╗██╗   ██╗
  ██║     ██║   ██║██╔════╝██║ ██╔╝╚██╗ ██╔╝
  ██║     ██║   ██║██║     █████╔╝  ╚████╔╝
  ██║     ██║   ██║██║     ██╔═██╗   ╚██╔╝
  ███████╗╚██████╔╝╚██████╗██║  ██╗   ██║
  ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝
`
"""


def patch(path: Path, pairs: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in pairs:
        if old not in text:
            print(f"  ! 未找到锚点 {path.name}: {old[:50]!r}")
            continue
        text = text.replace(old, new)
    if text != original:
        path.write_text(text, encoding="utf-8", newline="\n")
        print(f"  patched {path.relative_to(ROOT)}")
    else:
        print(f"  unchanged {path.relative_to(ROOT)}")


def main() -> None:
    print("== auth.go ==")
    patch(
        ROOT / "server" / "auth.go",
        [
            ('Subject:   "ARTEX",', 'Subject:   "Lucky",'),
            ('if req.Username != "ARTEX" {', 'if req.Username != "Lucky" && req.Username != "ARTEX" {'),
            ("// signJWT issues a 7-day HS256 token for user ARTEX.",
             "// signJWT issues a 7-day HS256 token for the operator account."),
        ],
    )

    print("== main.go ==")
    main_go = ROOT / "cmd" / "artex" / "main.go"
    text = main_go.read_text(encoding="utf-8")
    start = text.index(BANNER_OLD_START)
    end = text.index(BANNER_OLD_END, text.index("`", start + len(BANNER_OLD_START))) + len(BANNER_OLD_END)
    text = text[:start] + BANNER_NEW + text[end:]
    main_go.write_text(text, encoding="utf-8", newline="\n")
    print("  banner replaced")
    patch(
        main_go,
        [
            ('log.Printf("ARTEX %s backend listening on %s (data=%s, workers=%d)"',
             'log.Printf("Lucky %s backend listening on %s (data=%s, workers=%d)"'),
        ],
    )

    print("== mcp_server.go ==")
    patch(
        ROOT / "server" / "mcp_server.go",
        [
            ('map[string]any{"name": "artex", "title": "ARTEX", "version": BuildVersion}',
             'map[string]any{"name": "lucky", "title": "Lucky", "version": BuildVersion}'),
        ],
    )


if __name__ == "__main__":
    main()
