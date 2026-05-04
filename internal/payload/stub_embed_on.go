//go:build stubembed

package payload

import (
	"embed"
	"os"
)

// 将编好的模板放进 stubbin/：windows_x64.exe、linux_amd64.elf（shellcode 与 bin 共用；Windows 壳代码在服务端再走 renut）。
// 目录内至少需有一个文件以便 go:embed 通过（仓库自带 README.txt）。
//
//	go build -tags=stubembed
//
//go:embed stubbin/*
var embeddedPayloadStubs embed.FS

func tryLoadEmbeddedStub(osKey, format string) ([]byte, error) {
	name := stubTemplateFile(osKey, format)
	if name == "" {
		return nil, os.ErrNotExist
	}
	b, err := embeddedPayloadStubs.ReadFile("stubbin/" + name)
	if err != nil {
		return nil, err
	}
	if len(b) == 0 {
		return nil, os.ErrNotExist
	}
	return b, nil
}
