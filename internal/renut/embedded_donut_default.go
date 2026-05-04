//go:build !donutembed

package renut

// tryEmbeddedDonut 非 donutembed 构建：无二进制内嵌。
func tryEmbeddedDonut() (path string, hasEmbeddedBuild bool, err error) {
	return "", false, nil
}
