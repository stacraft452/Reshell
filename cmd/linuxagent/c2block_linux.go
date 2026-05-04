//go:build linux

package main

import (
	_ "embed"

	"c2/internal/c2embed"
)

//go:embed c2_template.bin
var c2ExecutableEmbedBlock []byte

func init() {
	if len(c2ExecutableEmbedBlock) != c2embed.TotalSize {
		panic("cmd/linuxagent: c2_template.bin 长度须为 c2embed.TotalSize")
	}
}
