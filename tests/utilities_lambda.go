package test

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"testing"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/logger"
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

	terraform.Init(t, terraformOptions)

	if variant == "docker" {
		ecrTargetTerraformOptions := &terraform.Options{
			TerraformDir: terraformDir,
			LockTimeout:  "5m",
			Targets:      []string{"module.ecr"},
		}

		terraform.Apply(t, ecrTargetTerraformOptions)

		ecrRepo := terraform.Output(t, ecrTargetTerraformOptions, "ecr_repo_url")

		tag := fmt.Sprintf("%s:latest", ecrRepo)
		buildOptions := &docker.BuildOptions{
			Tags: []string{tag},
		}

		docker.Build(t, "../examples/src-docker", buildOptions)

		// We can test the image locally before pushing it to ECR

		logger := logger.Terratest

		runOptions := &docker.RunOptions{
			Remove: true,
			Detach: true,
			Name:   variant,
			OtherOptions: []string{
				"-p", "8080:8080",
			},
		}

		docker.Run(t, tag, runOptions)
		defer docker.Stop(t, []string{variant}, &docker.StopOptions{Time: 5, Logger: logger})

		payload := []byte(`{}`)

		req, err := http.NewRequest("POST", "http://localhost:8080/2015-03-31/functions/function/invocations", bytes.NewBuffer(payload))

		if err != nil {
			t.Fatal(err)
		}

		req.Header.Set("Content-Type", "application/json")

		resp, err := http.DefaultClient.Do(req)

		if err != nil {
			t.Fatal(err)
		}

		defer resp.Body.Close()

		assert.Equal(t, 200, resp.StatusCode)

		body, err := ioutil.ReadAll(resp.Body)

		if err != nil {
			t.Fatal(err)
		}

		assert.Equal(t, "\"Hello Ishmael!\"", string(body))

		docker.Push(t, logger, tag)
	}

	terraform.Apply(t, terraformOptions)

	arn := terraform.Output(t, terraformOptions, "arn")
	name := terraform.Output(t, terraformOptions, "name")
	qualifiedARN := terraform.Output(t, terraformOptions, "qualified_arn")

	region := getAWSRegion(t)
	accountID := getAWSAccountID(t)

	expectedName := fmt.Sprintf("example-tf-pbs-lambda-%s", variant)
	expectedARN := fmt.Sprintf("arn:aws:lambda:%s:%s:function:%s", region, accountID, expectedName)

	expectedResponse := "\"Hello Jane!\""
	if variant == "env" {
		expectedResponse = "\"Hello Sarah!\""
	}
	if variant == "ssm" {
		expectedResponse = "\"Hello John!\""
	}
	if variant == "app-config" {
		expectedResponse = "\"Hello Billy!\""
	}
	if variant == "docker" {
		expectedResponse = "\"Hello Ishmael!\""
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
