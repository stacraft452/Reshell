package payload

import (
	"path/filepath"
	"strings"
)

// DownloadAttachmentName 供 Content-Disposition / 浏览器 download 属性使用（固定为 stubs 同名，便于识别）。
func DownloadAttachmentName(storedBasename string) string {
	base := filepath.Base(storedBasename)
	if !strings.HasPrefix(base, "payload_") {
		return base
	}
	switch {
	case strings.Contains(base, "_windows_x64_sc_") && strings.HasSuffix(base, ".bin"):
		return "shellcode_windows_x64.bin"
	case strings.Contains(base, "_linux_amd64_sc_") && strings.HasSuffix(base, ".bin"):
		return "shellcode_linux_amd64.bin"
	case strings.Contains(base, "_windows_x64_") && strings.HasSuffix(base, ".exe"):
		return "windows_x64.exe"
	case strings.Contains(base, "_linux_amd64_") && strings.HasSuffix(base, ".elf"):
		return "linux_amd64.elf"
	default:
		return base
	}
}
