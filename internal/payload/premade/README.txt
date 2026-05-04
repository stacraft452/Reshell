windows_amd64_sc_e1.bin — premade Windows shellcode (Donut -e1, embedded PE plaintext).

Regenerate on Windows after changing the Windows stub PE (C2EMBED layout or client):
  .\scripts\gen-premade-windows-shellcode.ps1

Then rebuild the Go server so //go:embed picks up the new file.
