// 生成示例载荷（占位回连），供仓库 artifacts 或发布说明使用。
// 用法（仓库根目录）：
//
//	go run ./cmd/gen-sample-payloads
//	go run ./cmd/gen-sample-payloads -os windows
//	go run ./cmd/gen-sample-payloads -os linux
//
// 可选环境变量：C2_GEN_PAYLOAD_OUT_DIR 指定输出目录（默认 data/generated）。
package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"c2/internal/payload"
)

func main() {
	log.SetFlags(0)
	osFlag := flag.String("os", "all", "生成目标: all | windows | linux")
	flag.Parse()

	baseCfg := payload.Config{
		ListenerID:        0,
		Mode:              "tcp",
		ServerAddr:        "127.0.0.1:8080",
		ExternalAddr:      "127.0.0.1:4444",
		ListenAddr:        "0.0.0.0:4444",
		VKey:              "sample-vkey-replace-in-production",
		Salt:              "sample-salt-replace-in-production",
		Arch:              "amd64",
		HeartbeatInterval: 30,
		WebHost:           "127.0.0.1",
		WebPort:           8080,
		HideConsole:       false,
	}

	tasks := []struct {
		os     string
		format string
		name   string
	}{
		{"windows_x64", "bin", "Windows x64 EXE"},
		{"linux_amd64", "bin", "Linux amd64 ELF"},
	}
	switch *osFlag {
	case "all":
	case "windows":
		tasks = tasks[:1]
	case "linux":
		tasks = tasks[1:]
	default:
		log.Fatalf("-os must be all, windows, or linux, got %q", *osFlag)
	}

	g := payload.NewGenerator()
	for _, tc := range tasks {
		cfg := baseCfg
		cfg.OS = tc.os
		cfg.Format = tc.format
		fn, err := g.Generate(&cfg)
		if err != nil {
			log.Fatalf("%s: %v", tc.name, err)
		}
		fmt.Println(fn)
	}
	if d := os.Getenv("C2_GEN_PAYLOAD_OUT_DIR"); d != "" {
		fmt.Fprintf(os.Stderr, "Output dir: %s\n", d)
	}
}
