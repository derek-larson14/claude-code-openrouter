#!/usr/bin/env bash
#
# OpenRouter CLI - Call external LLMs via OpenRouter using curl
#
# Usage:
#   openrouter.sh --model <model> --query "<query>" --output <file.md> [options]
#
# Examples:
#   openrouter.sh --model kimi --query "Write a story" --output story.md
#   openrouter.sh --model grok --query "Analyze this" --system-prompt "You are an analyst" --output analysis.md
#

set -eo pipefail

# Find models.conf file in same directory as script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_CONF="$SCRIPT_DIR/models.conf"

# Check if models.conf exists
if [[ ! -f "$MODELS_CONF" ]]; then
    echo "Error: models.conf not found at $MODELS_CONF" >&2
    echo "Please ensure models.conf is in the same directory as this script" >&2
    exit 1
fi

# Get model ID for a given model name
get_model_id() {
    # Read models.conf and find matching model
    # awk handles any amount of whitespace between fields
    awk -v model="$1" '
        !/^#/ && NF >= 2 && $1 == model { print $2; exit }
    ' "$MODELS_CONF"
}

# Get provider preference for a given model (if any)
get_model_provider() {
    # Read models.conf and find provider (third field if exists)
    awk -v model="$1" '
        !/^#/ && NF >= 3 && $1 == model { print $3; exit }
    ' "$MODELS_CONF"
}

# Default values
TEMPERATURE=0.7
MAX_TOKENS=4000
SYSTEM_PROMPT=""
CONTEXT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --query)
            QUERY="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --system-prompt)
            SYSTEM_PROMPT="$2"
            shift 2
            ;;
        --context-file)
            CONTEXT_FILE="$2"
            shift 2
            ;;
        --temperature)
            TEMPERATURE="$2"
            shift 2
            ;;
        --max-tokens)
            MAX_TOKENS="$2"
            shift 2
            ;;
        --json-output)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check required arguments
if [[ -z "${MODEL:-}" ]]; then
    echo "Error: --model is required" >&2
    echo "Available models (from models.conf):" >&2
    awk '!/^#/ && NF >= 2 { print "  " $1 }' "$MODELS_CONF" >&2
    exit 1
fi

if [[ -z "${QUERY:-}" ]]; then
    echo "Error: --query is required" >&2
    exit 1
fi

if [[ -z "${OUTPUT:-}" ]]; then
    echo "Error: --output is required" >&2
    exit 1
fi

# Auto-load API key from .env if it exists and key not already set
if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    # Try to find .env file in multiple locations
    # Check these locations in order:
    # 1. Current working directory
    # 2. Script directory
    # 3. Parent of script directory
    # 4. User's home directory
    # 5. OPENROUTER_CONFIG_DIR if set
    ENV_LOCATIONS=(
        "./.env"
        "$SCRIPT_DIR/.env"
        "$SCRIPT_DIR/../.env"
        "$HOME/.openrouter.env"
        "${OPENROUTER_CONFIG_DIR:+$OPENROUTER_CONFIG_DIR/.env}"
    )

    for location in "${ENV_LOCATIONS[@]}"; do
        if [[ -n "$location" ]] && [[ -f "$location" ]]; then
            source "$location"
            break
        fi
    done
fi

# Check API key after attempting to load from .env
if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    echo "Error: OPENROUTER_API_KEY not found" >&2
    echo "Please set it as an environment variable or add it to .env file" >&2
    exit 1
fi

# Get model ID
MODEL_ID=$(get_model_id "$MODEL")
if [[ -z "$MODEL_ID" ]]; then
    echo "Error: Unknown model '$MODEL'" >&2
    echo "Available models (from models.conf):" >&2
    awk '!/^#/ && NF >= 2 { print "  " $1 }' "$MODELS_CONF" >&2
    echo "" >&2
    echo "To add new models, edit: $MODELS_CONF" >&2
    exit 1
fi

# Load context file if provided
if [[ -n "$CONTEXT_FILE" ]] && [[ -f "$CONTEXT_FILE" ]]; then
    CONTEXT_CONTENT=$(cat "$CONTEXT_FILE")
    QUERY="$CONTEXT_CONTENT

$QUERY"
fi

# Build messages array
MESSAGES='[]'
if [[ -n "$SYSTEM_PROMPT" ]]; then
    MESSAGES=$(jq -n --arg content "$SYSTEM_PROMPT" '[{"role": "system", "content": $content}]')
fi
MESSAGES=$(echo "$MESSAGES" | jq --arg content "$QUERY" '. + [{"role": "user", "content": $content}]')

# Check if this model has a preferred provider
PROVIDER=$(get_model_provider "$MODEL")

# Build request body
if [[ -n "$PROVIDER" ]]; then
    # Include provider specification with no fallbacks
    REQUEST_BODY=$(jq -n \
        --arg model "$MODEL_ID" \
        --argjson messages "$MESSAGES" \
        --argjson temperature "$TEMPERATURE" \
        --argjson max_tokens "$MAX_TOKENS" \
        --arg provider "$PROVIDER" \
        '{
            model: $model,
            messages: $messages,
            temperature: $temperature,
            max_tokens: $max_tokens,
            provider: {
                order: [$provider],
                allow_fallbacks: false
            }
        }')
else
    # Standard request without provider specification
    REQUEST_BODY=$(jq -n \
        --arg model "$MODEL_ID" \
        --argjson messages "$MESSAGES" \
        --argjson temperature "$TEMPERATURE" \
        --argjson max_tokens "$MAX_TOKENS" \
        '{
            model: $model,
            messages: $messages,
            temperature: $temperature,
            max_tokens: $max_tokens
        }')
fi

# Make API call
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "$REQUEST_BODY")

# Check for errors
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // .error')
    echo "Error calling model: $ERROR_MSG" >&2
    exit 1
fi

# Extract content
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')
if [[ -z "$CONTENT" ]]; then
    echo "Error: Empty response from model" >&2
    exit 1
fi

# Create parent directories if needed
mkdir -p "$(dirname "$OUTPUT")"

# Write to file
echo "$CONTENT" > "$OUTPUT"

# Extract metadata
TOKENS=$(echo "$RESPONSE" | jq -r '.usage.total_tokens // 0')
MODEL_USED=$(echo "$RESPONSE" | jq -r '.model // .id // "'$MODEL_ID'"')

# Output results
if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
    jq -n \
        --arg file_path "$(realpath "$OUTPUT")" \
        --arg model_used "$MODEL_USED" \
        --arg model_id "$MODEL_ID" \
        --argjson tokens "$TOKENS" \
        --arg query "$QUERY" \
        '{
            success: true,
            file_path: $file_path,
            model_used: $model_used,
            model_id: $model_id,
            tokens: $tokens,
            query: $query
        }'
else
    echo "✓ Generated content using $MODEL (${MODEL_ID})"
    echo "✓ Saved to: $(realpath "$OUTPUT")"
    if [[ "$TOKENS" != "0" ]]; then
        echo "✓ Tokens used: $TOKENS"
    fi
fi
