# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go-based AWS Lambda function that provides a text analysis API via API Gateway. The function counts characters, bytes, and Unicode runes in text input, with support for Japanese and other Unicode text.

## Development Commands

### Build and Test
```bash
# Run tests
go test -v ./...

# Build Lambda function for deployment
make build

# Clean build artifacts
make clean

# Deploy to AWS (requires AWS CLI configuration)
make deploy
```

### Local Development
The project uses standard Go tooling without a go.mod file. Dependencies are managed through the AWS Lambda Go SDK.

## Architecture

### Core Components
- `main.go` - Lambda handler function that processes text analysis requests
- `main_test.go` - Test cases covering Japanese/English text and error scenarios
- `makefile` - Build automation for cross-compilation and AWS deployment
- `infrastructure/main.tf` - Terraform configuration for AWS infrastructure

### Infrastructure
- **Lambda Function**: `char-counter-lambda` running on `provided.al2` runtime
- **API Gateway**: REST API with `/count` endpoint accepting POST requests
- **IAM Role**: Basic execution role for Lambda with CloudWatch logging

### Request/Response Flow
1. API Gateway receives POST request at `/count` endpoint
2. Lambda handler parses JSON body with `{"text": "string"}` format
3. Function calculates three metrics:
   - `char_count`: Byte length
   - `byte_count`: Explicit byte count
   - `rune_count`: Unicode character count
4. Returns JSON response with analysis results

## Deployment

The project uses GitHub Actions for CI/CD with Terraform for infrastructure management. Deployment triggers automatically on pushes to `main` branch after tests pass.

Manual deployment requires:
1. AWS credentials configured
2. `make build` to create deployment package
3. Terraform commands in `infrastructure/` directory