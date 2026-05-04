Embedded Donut (go build -tags=donutembed)

Windows (native or GOOS=windows cross-build from any host):
  1. Place Windows PE Donut CLI as: donutbin/donut.exe
  2. go build -tags=donutembed -o c2-server.exe ./cmd/server

Linux / macOS server binary (GOOS=linux or darwin with donutembed):
  1. Build Donut from source on that OS (or use a published ELF for your arch).
     Example (Donut upstream): clone TheWover/donut, run make, copy the produced
     native executable to this directory as: donutbin/donut
  2. go build -tags=donutembed -o c2-server ./cmd/server

Notes:
  - donut.exe is Windows-only; Linux/macOS embed must use the native binary named "donut".
  - C2_RENUT_EXE still overrides both embedded and data/renut/* copies at runtime.
  - Shellcode is built from the already C2-patched PE; Donut must run once per payload.
    Pre-generating -e1 blobs and byte-patching cannot replace that for new listeners.
