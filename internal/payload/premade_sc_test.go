package payload

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"c2/internal/c2embed"
)

func TestPremadeWindowsSCE1ContainsPatchableC2Embed(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	p := filepath.Join(filepath.Dir(file), "premade", "windows_amd64_sc_e1.bin")
	raw, err := os.ReadFile(p)
	if err != nil {
		t.Skip("run scripts/gen-premade-windows-shellcode.ps1 on Windows first")
	}
	off := c2embed.FindPatchOffset(raw)
	if off < 0 {
		t.Fatal("FindPatchOffset: no C2EMBED in premade shellcode (need Donut -e1 from current stub)")
	}
	if _, err := c2embed.ParseAt(raw, off); err != nil {
		t.Fatal(err)
	}
}
