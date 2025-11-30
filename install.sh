#!/bin/bash
# Install external LLM agent into an existing Claude Code project

set -e

REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/dereklarson/openrouter-claude-code/main}"

echo "Installing external LLM agent..."

# Download core files
curl -sLO "$REPO_URL/openrouter.sh"
curl -sLO "$REPO_URL/models.conf"
chmod +x openrouter.sh

# Create agent directory and download agent config
mkdir -p .claude/agents
curl -sL "$REPO_URL/.claude/agents/external-llm.md" -o .claude/agents/external-llm.md

# Append to CLAUDE.md if it exists, otherwise create it
CLAUDE_SNIPPET='# External LLMs

To use external models (kimi, grok, grok-fast, glm, gemini, gpt-5), just mention them in your response:

- "I'\''ll use kimi to write this"
- "Let me ask grok about that"
- "Using gemini to analyze this"

Add "external-llm" if not triggering automatically.

Never run openrouter.sh directly - the agent handles everything.'

if [ -f "CLAUDE.md" ]; then
    echo "" >> CLAUDE.md
    echo "$CLAUDE_SNIPPET" >> CLAUDE.md
    echo "Updated CLAUDE.md"
else
    echo "$CLAUDE_SNIPPET" > CLAUDE.md
    echo "Created CLAUDE.md"
fi

# Add .env to .gitignore if it exists
if [ -f ".gitignore" ]; then
    grep -qxF ".env" .gitignore || echo ".env" >> .gitignore
    echo "Updated .gitignore"
fi

echo ""
echo "Done! Now add your API key:"
echo "  echo \"OPENROUTER_API_KEY=your-key\" > .env"
echo ""
echo "Get a key at https://openrouter.ai"
