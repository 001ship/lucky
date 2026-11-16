"""把启动横幅改成 codepage 安全的纯 ASCII，避免 Windows GBK 控制台乱码。"""

from pathlib import Path

p = Path(r"C:\Users\111111\Desktop\999\lucky\cmd\artex\main.go")
text = p.read_text(encoding="utf-8")

start = text.index("const banner = `")
end = text.index("`\n", start + len("const banner = `")) + 2

new_banner = """const banner = `
  Lucky   ·   any
`
"""
text = text[:start] + new_banner + text[end:]

old_print = '''func printBanner(addr string) {
	fmt.Print(banner)
	fmt.Println("  AI \u81ea\u4e3b\u6e17\u900f\u6d4b\u8bd5\u7cfb\u7edf")
	fmt.Printf("  \u7248\u672c %s  \u00b7  %s/%s  \u00b7  %s  \u00b7  \u76d1\u542c %s\\n\\n",
		version, runtime.GOOS, runtime.GOARCH, runtime.Version(), addr)
}'''

new_print = '''func printBanner(addr string) {
	fmt.Print(banner)
	fmt.Printf("  v%s  .  %s/%s  .  %s  .  listening %s\\n\\n",
		version, runtime.GOOS, runtime.GOARCH, runtime.Version(), addr)
}'''

if old_print in text:
    text = text.replace(old_print, new_print)
    print("printBanner replaced")
else:
    print("! printBanner anchor not found — 手工检查")

p.write_text(text, encoding="utf-8", newline="\n")
print("banner updated")
