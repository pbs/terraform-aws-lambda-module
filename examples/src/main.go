package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ssm"
)

// MyEvent My event
type MyEvent struct {
	Name string `json:"name"`
}

// Get environment variable, and fallback to a default otherwise
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// Attempt to pull from SSM Parameter Store both by path and by key
func getSSMParam(path string, key string) (string, error) {
	// Get the value from SSM Parameter Store
	sess := session.Must(session.NewSession())
	ssmSvc := ssm.New(sess)
	_, err := ssmSvc.GetParametersByPath(&ssm.GetParametersByPathInput{
		Path:           aws.String(path),
		Recursive:      aws.Bool(true),
		WithDecryption: aws.Bool(true),
	})
	if err != nil {
		fmt.Printf("Error getting SSM parameters for path %s: %s\n", path, err)
		return "", err
	}

	paramName := fmt.Sprintf("%s/%s", path, key)

	ssmParam, err := ssmSvc.GetParameter(&ssm.GetParameterInput{
		Name:           &paramName,
		WithDecryption: aws.Bool(true),
	})

	if err != nil {
		fmt.Printf("Error getting SSM Parameter Store value for key %s: %s\n", key, err.Error())
		return "", err
	}
	return *ssmParam.Parameter.Value, nil
}

// HandleRequest Handles a request of the event matching MyEvent
func HandleRequest(ctx context.Context, name MyEvent) (string, error) {
	greetingName := getEnv("NAME", name.Name)

	ssmPath := getEnv("SSM_PATH", "/")
	ssmGreetingName, err := getSSMParam(ssmPath, "name")

	if err == nil {
		greetingName = ssmGreetingName
	}

	return fmt.Sprintf("Hello %s!", greetingName), nil
}

func main() {
	lambda.Start(HandleRequest)
}
