//go:build donutembed && windows

package renut

import _ "embed"

//go:embed donutbin/donut.exe
var donutExeEmbedded []byte
