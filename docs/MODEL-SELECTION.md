# Choosing Your Model

Pixel can use any OpenCode model. Here's how to select one:

## Quick Selection

Edit `~/.config/oc-companion/config.json`:

```json
{
  "agent": "Build",
  "model": "omniroute/kr/claude-haiku-4.5",
  ...
}
```

The `model` field uses the format `provider/model` or `provider/model-id`.

## Finding Available Models

### Option 1: Check OpenCode web interface
Open your OpenCode dashboard and look at available models.

### Option 2: Use the API
```bash
curl http://localhost:4096/api/models | jq '.[]'
```

### Option 3: Ask Pixel herself
Once she's running:
```bash
oc-companion ask "what models are available?"
```

## Common Models

Examples (adjust based on your OpenCode setup):

```json
"model": "omniroute/kr/claude-sonnet-4.5"        // Balanced
"model": "omniroute/kr/claude-haiku-4.5"         // Fast & cheap
"model": "anthropic/claude-3-5-sonnet-20241022"  // Direct API
"model": "openrouter/anthropic/claude-3.5-sonnet"
```

## Model vs visionModel

- **`model`** - Used for normal text conversations
- **`visionModel`** - Automatically used when you attach images (must support vision)

Example config:
```json
{
  "model": "omniroute/kr/claude-haiku-4.5",
  "visionModel": "opencode/nemotron-3.5-super-vl-free",
  ...
}
```

When you press `SUPER+ALT+I` to attach an image, she switches to `visionModel` for that one message, then switches back.

## Omit to Use Agent Default

If you leave out the `model` field entirely, she uses whatever model the `Build` agent (or your chosen agent) is configured to use:

```json
{
  "agent": "Build",
  // "model": not specified - uses Build agent's default
  ...
}
```

## Apply Changes

After editing:
```bash
oc-companion reload
```

The next message uses the new model. No restart needed.

## Cost Considerations

Different models have different costs:
- **Haiku** - Fastest, cheapest, good for quick tasks
- **Sonnet** - Balanced, good default
- **Opus** - Most capable, slowest, most expensive

Choose based on your needs and OpenCode credits/API limits.
