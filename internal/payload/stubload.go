package payload

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// 模板文件名与目标 OS 对应关系（须放在 data/stubs/ 或 C2_STUB_DIR 或内嵌 stubbin）：
//
//	format bin:
//	  windows_x64  → windows_x64.exe
//	  linux_amd64  → linux_amd64.elf
//
//	format shellcode：
//	  Windows 服务端 → PE 模板修补后由 renut/Donut -e3 生成 .bin
//	  非 Windows 服务端 → 使用 go:embed 预置 Donut -e1 的 .bin，仅 PatchC2Embed 改回连（不执行 Donut）
//	  Linux + shellcode 目标 OS 仍不支持（仅 Windows 目标可出 .bin）
func stubTemplateName(osKey string) string {
	switch osKey {
	case "windows_x64":
		return "windows_x64.exe"
	case "linux_amd64":
		return "linux_amd64.elf"
	default:
		return ""
	}
}

func stubTemplateFile(osKey, format string) string {
	// shellcode 与 bin 共用同一 PE/ELF 模板；Windows 壳代码在生成阶段再走 renut。
	return stubTemplateName(osKey)
}

// StubTemplatePathForOS 返回应在 stubs 目录中存在的文件名（用于错误提示）。
func StubTemplatePathForOS(osKey string) string {
	n := stubTemplateName(osKey)
	if n == "" {
		return ""
	}
	return filepath.Join(RelPathStubs, n)
}

// StubTemplatePath 返回指定格式下的模板相对路径（用于错误提示）。
func StubTemplatePath(osKey, format string) string {
	n := stubTemplateFile(osKey, format)
	if n == "" {
		return ""
	}
	return filepath.Join(RelPathStubs, n)
}

// loadStubTemplate 加载未修补模板：内嵌（-tags=stubembed）→ C2_STUB_DIR → 可执行文件旁 data/stubs → 当前工作目录 data/stubs。
func loadStubTemplate(osKey, format string) ([]byte, error) {
	name := stubTemplateFile(osKey, format)
	if name == "" {
		return nil, fmt.Errorf("unsupported OS %q / format %q", osKey, format)
	}
	if b, err := tryLoadEmbeddedStub(osKey, format); err == nil && len(b) > 0 {
		return b, nil
	}
	var paths []string
	if d := strings.TrimSpace(os.Getenv("C2_STUB_DIR")); d != "" {
		paths = append(paths, filepath.Join(d, name))
	}
	if exe, err := os.Executable(); err == nil {
		ed := filepath.Dir(exe)
		paths = append(paths, filepath.Join(ed, RelPathStubs, name))
	}
	paths = append(paths, filepath.Join(RelPathStubs, name))

	var lastErr error
	for _, p := range paths {
		if p == "" {
			continue
		}
		data, err := ioutil.ReadFile(p)
		if err != nil {
			lastErr = err
			continue
		}
		if len(data) > 0 {
			return data, nil
		}
	}
	if lastErr != nil {
		return nil, fmt.Errorf("未找到模板 %s（已尝试 C2_STUB_DIR、程序旁与 cwd 下的 %s）: %w", name, RelPathStubs, lastErr)
	}
	return nil, fmt.Errorf("未找到模板 %s，请将文件放入 %s/", name, RelPathStubs)
}
