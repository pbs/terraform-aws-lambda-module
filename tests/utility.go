package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/sts"
)

// MyEvent My event
type MyEvent struct {
	Name string `json:"name"`
}

func invokeLambda(t *testing.T, lambdaName string) (*lambda.InvokeOutput, error) {
	session, err := session.NewSession()
	if err != nil {
		t.Fatalf("Failed to create AWS session: %v", err)
		return nil, err
	}
	svc := lambda.New(session)
	input := &lambda.InvokeInput{
		FunctionName: aws.String(lambdaName),
		Payload:      []byte("{\"name\": \"Jane\"}"),
	}
	result, err := svc.Invoke(input)

	if err != nil {
		t.Fatalf("Failed to invoke lambda: %v", err)
		return nil, err
	}
	return result, nil
}

func deleteLogGroup(t *testing.T, logGroupName string) {
	session, err := session.NewSession()
	if err != nil {
		t.Fatalf("Failed to create AWS session: %v", err)
	}
	svc := cloudwatchlogs.New(session)
	input := cloudwatchlogs.DeleteLogGroupInput{
		LogGroupName: &logGroupName,
	}
	_, err = svc.DeleteLogGroup(&input)
	if err != nil {
		t.Logf("Failed to delete log group: %v.\nThis is probably OK, as we're just making sure it's not there.", err)
	}
}

func getAWSAccountID(t *testing.T) string {
	session, err := session.NewSession()
	if err != nil {
		t.Fatalf("Failed to create AWS session: %v", err)
		return ""
	}
	svc := sts.New(session)
	result, err := svc.GetCallerIdentity(&sts.GetCallerIdentityInput{})
	if err != nil {
		t.Fatalf("Failed to get AWS Account ID: %v", err)
		return ""
	}
	return *result.Account
}

func getAWSRegion(t *testing.T) string {
	session, err := session.NewSession()
	if err != nil {
		t.Fatalf("Failed to create AWS session: %v", err)
		return ""
	}
	return *session.Config.Region
}
