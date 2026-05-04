//go:build donutembed

package renut

import (
	"fmt"
	"os"
	"runtime"
	"sync"
)

var (
	embeddedOnce sync.Once
	embeddedPath string
	embeddedErr  error
)

func extractEmbeddedDonut() {
	if len(donutExeEmbedded) < 1024 {
		embeddedErr = fmt.Errorf("renut: 内嵌 Donut 无效或过小（见 internal/renut/donutbin/README.txt）")
		return
	}
	if runtime.GOOS == "linux" {
		if len(donutExeEmbedded) < 4 || donutExeEmbedded[0] != 0x7f || donutExeEmbedded[1] != 'E' || donutExeEmbedded[2] != 'L' || donutExeEmbedded[3] != 'F' {
			embeddedErr = fmt.Errorf("renut: donutbin/donut 须为 Linux ELF（勿把 Windows 的 donut.exe 改名放入；见 donutbin/README.txt）")
			return
		}
	}
	pattern := "c2-embedded-donut-*"
	if runtime.GOOS == "windows" {
		pattern = "c2-embedded-donut-*.exe"
	}
	f, err := os.CreateTemp("", pattern)
	if err != nil {
		embeddedErr = fmt.Errorf("renut: 创建临时 Donut: %w", err)
		return
	}
	tmp := f.Name()
	if _, err := f.Write(donutExeEmbedded); err != nil {
		_ = f.Close()
		_ = os.Remove(tmp)
		embeddedErr = fmt.Errorf("renut: 写出内嵌 Donut: %w", err)
		return
	}
	if err := f.Close(); err != nil {
		_ = os.Remove(tmp)
		embeddedErr = err
		return
	}
	if runtime.GOOS != "windows" {
		if err := os.Chmod(tmp, 0755); err != nil {
			_ = os.Remove(tmp)
			embeddedErr = fmt.Errorf("renut: chmod 临时 Donut: %w", err)
			return
		}
	}
	embeddedPath = tmp
}

// tryEmbeddedDonut 将内嵌的 Donut 解压到临时目录（每进程一次）。
func tryEmbeddedDonut() (path string, hasEmbeddedBuild bool, err error) {
	embeddedOnce.Do(extractEmbeddedDonut)
	if embeddedErr != nil {
		return "", true, embeddedErr
	}
	return embeddedPath, true, nil
}
