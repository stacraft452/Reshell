// Package renut 封装 Donut：对已修补 C2 配置的 Windows PE 生成默认加密（-e3）壳代码。
package renut

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

// RelPathRenut 相对可执行文件 / 工作目录，放置 donut.exe 或 renut.exe（与 Donut 同源构建）。
const RelPathRenut = "data/renut"

func fileExists(p string) bool {
	st, err := os.Stat(p)
	return err == nil && !st.IsDir()
}

// ResolveExecutable 查找 Donut/renut 可执行文件。
// 顺序：环境变量 C2_RENUT_EXE → 程序目录下 data/renut/donut.exe → data/renut/renut.exe → 工作目录下相同相对路径。
func ResolveExecutable() (string, error) {
	if p := os.Getenv("C2_RENUT_EXE"); p != "" {
		if fileExists(p) {
			return p, nil
		}
		return "", fmt.Errorf("renut: C2_RENUT_EXE 指向的文件不存在: %s", p)
	}

	donutNames := []string{"donut", "donut.exe", "renut", "renut.exe"}
	if runtime.GOOS == "windows" {
		donutNames = []string{"donut.exe", "renut.exe", "donut", "renut"}
	}

	var candidates []string
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		for _, n := range donutNames {
			candidates = append(candidates, filepath.Join(dir, RelPathRenut, n))
		}
	}
	if wd, err := os.Getwd(); err == nil {
		for _, n := range donutNames {
			candidates = append(candidates, filepath.Join(wd, RelPathRenut, n))
		}
	}

	for _, c := range candidates {
		if fileExists(c) {
			return filepath.Clean(c), nil
		}
	}

	if p, ok, err := tryEmbeddedDonut(); ok {
		if err != nil {
			return "", err
		}
		if fileExists(p) {
			return filepath.Clean(p), nil
		}
	}

	return "", fmt.Errorf("renut: 未找到 Donut 可执行文件：可将 donut.exe 放到可执行文件或工作目录下的 %s/，或设置 C2_RENUT_EXE；单文件发布请使用 go build -tags=donutembed（构建前将 donut.exe 放入 internal/renut/donutbin/）（已搜索外置路径 %d 处）", RelPathRenut, len(candidates))
}

// DonutArch 返回 Donut -a：当前 Windows PE 载荷仅为 amd64（2）。
func DonutArch(arch string) int {
	_ = arch
	return 2
}

// PackPEFile 对已落盘的 PE 调用 Donut，写入 shellcode 路径 outPath。
// 使用 -e 3（随机名 + Chaskey 加密实例/模块），与 Donut 默认一致。
func PackPEFile(pePath, outPath string, arch string) error {
	donutExe, err := ResolveExecutable()
	if err != nil {
		return err
	}
	a := DonutArch(arch)
	cmd := exec.Command(donutExe,
		"-i", pePath,
		"-o", outPath,
		"-a", fmt.Sprintf("%d", a),
		"-e", "3",
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("renut: Donut 执行失败: %w\n%s", err, string(out))
	}
	return nil
}

// PackPEBytes 将内存中的 PE 写入临时文件，调用 Donut 生成 shellcode，再删除临时文件。
func PackPEBytes(pe []byte, arch string, outPath string) error {
	f, err := os.CreateTemp("", "reshell-renut-*.exe")
	if err != nil {
		return fmt.Errorf("renut: 临时文件: %w", err)
	}
	tmpPath := f.Name()
	defer func() { _ = os.Remove(tmpPath) }()

	if _, err := f.Write(pe); err != nil {
		_ = f.Close()
		return fmt.Errorf("renut: 写临时 PE: %w", err)
	}
	if err := f.Close(); err != nil {
		return err
	}
	return PackPEFile(tmpPath, outPath, arch)
}
