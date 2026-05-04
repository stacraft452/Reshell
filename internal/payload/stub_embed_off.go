//go:build !stubembed

package payload

import "os"

func tryLoadEmbeddedStub(osKey, format string) ([]byte, error) {
	_, _ = osKey, format
	return nil, os.ErrNotExist
}
