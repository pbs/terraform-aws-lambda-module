package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
)

// MyEvent My event
type MyEvent struct {
	Name string `json:"name"`
}

// Parameter
type Parameter struct {
	ARN              string `type:"string"`
	DataType         string `type:"string"`
	LastModifiedDate string `type:"string"`
	Name             string `type:"string"`
	Selector         string `type:"string"`
	SourceResult     string `type:"string"`
	Type             string `type:"string"`
	Value            string `type:"string"`
	Version          int64  `type:"integer"`
}

// SSM Parameters Response
type SSMParameter struct {
	Parameter Parameter `json:"Parameter"`
	// ResultMetadata ResultMetadata `json:"ResultMetadata"` // Don't need this
}

// Get environment variable, and fallback to a default otherwise
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func getSSMParamFromExtension(path string, name string) (SSMParameter, error) {
	// Get the value from the extension
	parameterPath := fmt.Sprintf("%s/%s", path, name)
	urlEncodedPath := url.QueryEscape(parameterPath)
	url := fmt.Sprintf("http://localhost:2773/systemsmanager/parameters/get/?name=%s&withDecryption=true", urlEncodedPath)
	log.Print(url)
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("X-Aws-Parameters-Secrets-Token", os.Getenv("AWS_SESSION_TOKEN"))
	res, _ := client.Do(req)
	defer res.Body.Close()
	body, _ := ioutil.ReadAll(res.Body)
	var ssmParam SSMParameter
	err := json.Unmarshal(body, &ssmParam)
	if err != nil {
		log.Print(err)
	}
	return ssmParam, err
}

// Attempt to pull from SSM Parameter Store both by path and by key. One of these
// approaches are what you should take if you don't want to use the new SSM Parameters
// extension. This will be the case on ARM until that's supported.

// func getSSMParam(path string, key string) (string, error) {
// 	// Get the value from SSM Parameter Store
// 	sess := session.Must(session.NewSession())
// 	ssmSvc := ssm.New(sess)
// 	_, err := ssmSvc.GetParametersByPath(&ssm.GetParametersByPathInput{
// 		Path:           aws.String(path),
// 		Recursive:      aws.Bool(true),
// 		WithDecryption: aws.Bool(true),
// 	})
// 	if err != nil {
// 		fmt.Printf("Error getting SSM parameters for path %s: %s\n", path, err)
// 		return "", err
// 	}

// 	paramName := fmt.Sprintf("%s/%s", path, key)

// 	ssmParam, err := ssmSvc.GetParameter(&ssm.GetParameterInput{
// 		Name:           &paramName,
// 		WithDecryption: aws.Bool(true),
// 	})

// 	if err != nil {
// 		fmt.Printf("Error getting SSM Parameter Store value for key %s: %s\n", key, err.Error())
// 		return "", err
// 	}
// 	return *ssmParam.Parameter.Value, nil
// }

// HandleRequest Handles a request of the event matching MyEvent
func HandleRequest(ctx context.Context, name MyEvent) (string, error) {
	greetingName := getEnv("NAME", name.Name)

	ssmPath := getEnv("SSM_PATH", "/")
	// ssmGreetingName, err := getSSMParam(ssmPath, "name")

	// if err == nil {
	// 	greetingName = ssmGreetingName
	// }

	ssmParameter, err := getSSMParamFromExtension(ssmPath, "name")

	if err == nil {
		greetingName = ssmParameter.Parameter.Value
	}

	return fmt.Sprintf("Hello %s!", greetingName), nil
}

func main() {
	lambda.Start(HandleRequest)
}
