//go:build donutembed && (linux || darwin)

package renut

import _ "embed"

//go:embed donutbin/donut
var donutExeEmbedded []byte
