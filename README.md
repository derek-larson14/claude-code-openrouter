# OpenRouter Claude Code Agent

Use external LLMs (Kimi, Grok, Gemini, GLM, GPT-5) directly from Claude Code by mentioning them in your prompts.

## How It Works in Claude Code

Simply mention the model name (add "external-llm" to your prompt if it is not triggering):

- "Use **kimi** to write a blog post about AI"
- "Ask **grok** to explain quantum computing"
- "Have **gemini** analyze this data"
- "Generate a marketing doc with gemini and context.md from the marketing folder use external-llm"

The agent will:
1. Detect when you mention an external model
2. Extract your actual request
3. Call the model via OpenRouter API
4. Save the response to `llm-outputs/` (or a custom path)
5. Show you the file location

> **First Use:** Claude Code will ask for approval the first time it runs `openrouter.sh`. Select option 2 ("Yes, and don't ask again...") to auto-approve future calls.

## Quick Setup

### 1. Get an API key from [OpenRouter.ai](https://openrouter.ai)

### 2. Save your API key
```bash
echo "OPENROUTER_API_KEY=your-key-here" > .env
```

That's it! Now you can use external models in Claude Code.

## Adding to an Existing Project

To integrate into your existing Claude Code project:

1. **Copy these files to your project root:**
   - `openrouter.sh` - The CLI script
   - `models.conf` - Model configuration
   - `CLAUDE.md` - Context file (optional. Append to your existing CLAUDE.md if you have one)

2. **Copy the agent configuration:**
   ```bash
   cp -r .claude/agents/external-llm.md your-project/.claude/agents/
   ```

3. **Add to your .gitignore:**
   ```
   .env
   llm-outputs/
   ```

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