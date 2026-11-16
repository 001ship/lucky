"""修复：品牌补丁把 import 插到了文件最前，抢占了 "use client" 指令位置。

把 `import { APP_CONFIG } ...` 从首行挪到 "use client" 指令之后（若无该指令则保持原位，
但插到第一个 import 之前的位置即可）。
"""

from pathlib import Path

ROOT = Path(r"C:\Users\111111\Desktop\999\lucky\web\src")
MARK = 'import { APP_CONFIG } from "@/config/app-config";'


def fix(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").split("\n")
    if not any(MARK in ln for ln in lines[:3]):
        return
    # 移除已插入的那一行
    lines = [ln for ln in lines if MARK not in ln]
    # 找 "use client" 指令
    idx = 0
    for i, ln in enumerate(lines[:5]):
        if ln.strip().strip('"').strip("'") == "use client":
            idx = i + 1
            break
    # 指令后通常有空行，插在空行之后
    while idx < len(lines) and lines[idx].strip() == "":
        idx += 1
    lines.insert(idx, MARK)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"fixed {path.relative_to(ROOT)} (use client at line {idx})")


def main() -> None:
    for p in ROOT.rglob("*.tsx"):
        fix(p)
    for p in ROOT.rglob("*.ts"):
        fix(p)


if __name__ == "__main__":
    main()
