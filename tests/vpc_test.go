package test

import (
	"testing"
)

func TestVPCExample(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping VPC test in short mode, as the test takes > 30 mins to delete ENIs.")
	}
	testLambda(t, "vpc")
}
