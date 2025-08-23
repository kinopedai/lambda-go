package main

import (
	"context"
	"encoding/json"
	"fmt"
	"unicode/utf8"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Request structure
type Request struct {
	Text string `json:"text"`
}

// Response structure
type Response struct {
	Message    string `json:"message"`
	CharCount  int    `json:"char_count"`
	ByteCount  int    `json:"byte_count"`
	RuneCount  int    `json:"rune_count"`
}

// Lambda handler function
func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Parse request body
	var req Request
	if err := json.Unmarshal([]byte(request.Body), &req); err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 400,
			Headers: map[string]string{
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*",
			},
			Body: `{"error": "Invalid JSON format"}`,
		}, nil
	}

	// Count characters
	text := req.Text
	charCount := len(text)           // バイト数
	runeCount := utf8.RuneCountInString(text) // 文字数（Unicode対応）
	byteCount := len([]byte(text))   // バイト数（明示的）

	// Create response
	response := Response{
		Message:   fmt.Sprintf("文字列「%s」を分析しました", text),
		CharCount: charCount,
		ByteCount: byteCount,
		RuneCount: runeCount,
	}

	responseBody, err := json.Marshal(response)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 500,
			Headers: map[string]string{
				"Content-Type": "application/json",
				"Access-Control-Allow-Origin": "*",
			},
			Body: `{"error": "Internal server error"}`,
		}, nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
			"Access-Control-Allow-Origin": "*",
		},
		Body: string(responseBody),
	}, nil
}

func main() {
	lambda.Start(handler)
}