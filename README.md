# OpenRouter Claude Code Agent

Use external LLMs (Kimi, Grok, Gemini, GLM, GPT-5) directly from Claude Code by mentioning them in your prompts.

## Setup

### New Project

Clone this repo and add your API key:

```bash
git clone https://github.com/derek-larson14/claude-code-openrouter.git external-llm-agent
cd external-llm-agent
echo "OPENROUTER_API_KEY=your-key-here" > .env
```

Get your API key from [OpenRouter.ai](https://openrouter.ai)

### Existing Project

Run this from your project directory:

```bash
curl -sL https://raw.githubusercontent.com/derek-larson14/claude-code-openrouter/main/install.sh | bash
```

Then add your API key:
```bash
echo "OPENROUTER_API_KEY=your-key-here" > .env
```

## Usage

In Claude Code, just mention the model name:

- "Use **kimi** to write a blog post about AI"
- "Ask **grok** to explain quantum computing"
- "Have **gemini** create a marketing presentation and use @marketing/project-plan.md as context"

Add "external-llm" to your prompt if it doesn't trigger automatically.

> **First Run:** Claude Code will ask for approval the first time. Select "Yes, and don't ask again..." to auto-approve future calls.

## Available Models

Default models configured in `models.conf`:
- **kimi** - Moonshot AI's K2 model (great for creative writing)
- **grok** - Grok 4 from X.AI
- **grok-fast** - Grok 4 Fast from X.AI
- **glm** - GLM-4.6 from Zhipu AI
- **gemini** - Gemini 2.5 Pro from Google
- **gpt-5** - GPT-5 from OpenAI

### Adding Your Own Models

Edit `models.conf` to add any OpenRouter model:

```
# Format: name    model_id    [provider]
mixtral  mistralai/mixtral-8x22b-instruct
llama    meta-llama/llama-4-maverick
```

Find model IDs at [OpenRouter.ai/models](https://openrouter.ai/models)

### Output Locations

**Default behavior** - saves to `llm-outputs/`:
```
"Use kimi to write a story about hope"
→ llm-outputs/kimi-story-hope.md
```

**Custom paths** - specify where to save:
```
"Ask gemini to summarize this, output to project/summary.txt"
→ project/summary.txt
```

## Direct CLI Usage

You can also use the script directly from the command line:

```bash
# Basic usage
./openrouter.sh --model kimi --query "Write a haiku about horses" --output horses.md

# With context
./openrouter.sh --model gemini \
  --query "Improve this code" \
  --context-file mycode.py \
  --output better.py

# With system prompt
./openrouter.sh --model grok \
  --query "Explain this concept" \
  --system-prompt "You are a teacher" \
  --output lesson.md
```

### CLI Options

- `--model` - Which model to use (from models.conf)
- `--query` - Your prompt
- `--output` - Where to save the response
- `--system-prompt` - Add instructions
- `--context-file` - Include file content
- `--temperature` - Creativity (0-2, default 0.7)
- `--max-tokens` - Max length (default 4000)

## File Locations

- API key: `.env` or `~/.openrouter.env`
- Model config: `models.conf`
- Generated files: `llm-outputs/`
- Agent config: `.claude/agents/external-llm.md`

## Troubleshooting

**"OPENROUTER_API_KEY not found"**
- Create `.env` with your API key

**"Unknown model"**
- Check model is listed in `models.conf`
- Model names are case-sensitive

**API errors**
- Verify your API key at [OpenRouter.ai](https://openrouter.ai)
- Check you have credits for the model

## Acknowledgments

Shoutout to [Alex Flores](https://x.com/ajflores1604) for helping create this.

## License

MIT
