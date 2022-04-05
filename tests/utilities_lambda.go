package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testLambda(t *testing.T, variant string) {
	t.Parallel()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	// This is annoying, but necessary. Log Group isn't cleaned up correctly after destroy.
	logGroupName := fmt.Sprintf("/aws/lambda/example-tf-pbs-lambda-%s", variant)
	deleteLogGroup(t, logGroupName)

	terraform.InitAndApply(t, terraformOptions)

	arn := terraform.Output(t, terraformOptions, "arn")
	name := terraform.Output(t, terraformOptions, "name")
	qualifiedARN := terraform.Output(t, terraformOptions, "qualified_arn")

	region := getAWSRegion(t)
	accountID := getAWSAccountID(t)

	expectedName := fmt.Sprintf("example-tf-pbs-lambda-%s", variant)
	expectedARN := fmt.Sprintf("arn:aws:lambda:%s:%s:function:%s", region, accountID, expectedName)

	expectedResponse := fmt.Sprintf("\"Hello Jane!\"")
	if variant == "env" {
		expectedResponse = fmt.Sprintf("\"Hello Sarah!\"")
	}
	if variant == "ssm" {
		expectedResponse = fmt.Sprintf("\"Hello John!\"")
	}

	assert.Equal(t, expectedARN, arn)
	assert.Equal(t, expectedName, name)
	assert.Contains(t, qualifiedARN, expectedARN)

	result, err := invokeLambda(t, name)
	if err != nil {
		assert.Equal(t, nil, err)
	}

	assert.Equal(t, expectedResponse, string(result.Payload))
}
