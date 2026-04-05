// Package webdist 将面板所需的 HTML 与静态资源嵌入二进制，部署时仅需可执行文件 + config.yaml。
package webdist

import "embed"

//go:embed templates static
var FS embed.FS
