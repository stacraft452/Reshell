package payload

// 路径约定（相对进程工作目录，或与可执行文件同目录）：
//
//	data/stubs/windows_x64.exe   ← 目标 OS：windows_x64，格式 bin
//	data/stubs/linux_amd64.elf   ← 目标 OS：linux_amd64，格式 bin
//
//	Windows 壳代码（format=shellcode）：模板仍为上述 PE；服务端修补 C2EMBED1 后调用 renut（Donut，默认 -e3）生成 .bin。
//	Donut 解析顺序：C2_RENUT_EXE → data/renut/donut.exe（相对 exe/cwd）→ 若使用 go build -tags=donutembed 则内嵌 donut（见 internal/renut/donutbin/）。
//
// 生成结果写入 data/generated/（不再使用 data/payloads）。
// 可选环境变量 C2_STUB_DIR 覆盖模板目录；可选 go build -tags=stubembed 内嵌 stubbin/*。

const (
	RelPathStubs     = "data/stubs"
	RelPathGenerated = "data/generated"
)
