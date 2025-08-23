package main

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	tests := []struct {
		name         string
		request      events.APIGatewayProxyRequest
		expectedCode int
		expectedText string
	}{
		{
			name: "Valid Japanese text",
			request: events.APIGatewayProxyRequest{
				Body: `{"text": "こんにちは"}`,
			},
			expectedCode: 200,
			expectedText: "こんにちは",
		},
		{
			name: "Valid English text",
			request: events.APIGatewayProxyRequest{
				Body: `{"text": "Hello World"}`,
			},
			expectedCode: 200,
			expectedText: "Hello World",
		},
		{
			name: "Empty text",
			request: events.APIGatewayProxyRequest{
				Body: `{"text": ""}`,
			},
			expectedCode: 200,
			expectedText: "",
		},
		{
			name: "Invalid JSON",
			request: events.APIGatewayProxyRequest{
				Body: `{"invalid": json}`,
			},
			expectedCode: 400,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			response, err := handler(context.Background(), tt.request)
			if err != nil {
				t.Errorf("handler returned error: %v", err)
			}

			if response.StatusCode != tt.expectedCode {
				t.Errorf("Expected status code %d, got %d", tt.expectedCode, response.StatusCode)
			}

			if tt.expectedCode == 200 {
				var resp Response
				err := json.Unmarshal([]byte(response.Body), &resp)
				if err != nil {
					t.Errorf("Failed to unmarshal response: %v", err)
				}

				if tt.expectedText != "" {
					expectedRuneCount := len([]rune(tt.expectedText))
					if resp.RuneCount != expectedRuneCount {
						t.Errorf("Expected rune count %d, got %d", expectedRuneCount, resp.RuneCount)
					}
				}
			}
		})
	}
}