Place your Donut build here for Windows shellcode generation (format=shellcode).

  donut.exe

The C2 server invokes it after patching C2EMBED1 in the PE stub (default flags: -e 3).

Single-binary deployment: embed Donut at compile time — copy donut.exe to
internal/renut/donutbin/donut.exe then:

  go build -tags=donutembed -o c2-server.exe ./cmd/server

Or run scripts\build-server-embed-donut.ps1 from the repo root.

Override path with environment variable:

  C2_RENUT_EXE=C:\path\to\donut.exe

Build Donut with MSVC (see donut-master Makefile.msvc) if MinGW fails on aplib.
