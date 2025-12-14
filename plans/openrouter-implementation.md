# OpenRouter Implementation Plan

## Overview

This plan outlines the implementation of OpenRouter as a new model provider in the Claude Code Model Switcher (CCM). OpenRouter is a unified API gateway that provides access to multiple AI models through a single interface, making it an excellent replacement for the removed PPInfra fallback service.

## Why OpenRouter?

- **Unified Interface**: Single API key for access to 100+ models
- **Cost-Effective**: Competitive pricing with flexible payment options
- **High Availability**: Reliable service with automatic failover
- **Wide Model Selection**: Access to models from multiple providers
- **Developer-Friendly**: OpenAI-compatible API format
- **Transparent**: Clear pricing and model information

## Implementation Steps

### Phase 1: Core Integration

#### 1.1 Add OpenRouter Configuration Variables

**Location**: `ccm.sh` - configuration section

```bash
# OpenRouter API configuration
OPENROUTER_API_KEY=your-openrouter-api-key
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
OPENROUTER_SMALL_FAST_MODEL=openai/gpt-4o-mini
```

**Tasks**:
- [ ] Add to `load_config()` function
- [ ] Add to configuration template in `show_config_template()`
- [ ] Add to status display in `show_status()`

#### 1.2 Implement OpenRouter Switching Function

**Location**: `ccm.sh` - new function

```bash
switch_to_openrouter() {
    local model_name="${1:-claude-3.5-sonnet}"

    if is_effectively_set "$OPENROUTER_API_KEY"; then
        export ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1"
        export ANTHROPIC_API_URL="https://openrouter.ai/api/v1"
        export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
        export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"

        # Map common model names to OpenRouter identifiers
        case "$model_name" in
            "sonnet"|"claude")
                export ANTHROPIC_MODEL="anthropic/claude-3.5-sonnet"
                export ANTHROPIC_SMALL_FAST_MODEL="openai/gpt-4o-mini"
                ;;
            "opus")
                export ANTHROPIC_MODEL="anthropic/claude-3-opus"
                export ANTHROPIC_SMALL_FAST_MODEL="anthropic/claude-3-haiku"
                ;;
            "haiku")
                export ANTHROPIC_MODEL="anthropic/claude-3-haiku"
                export ANTHROPIC_SMALL_FAST_MODEL="anthropic/claude-3-haiku"
                ;;
            "gpt4")
                export ANTHROPIC_MODEL="openai/gpt-4-turbo"
                export ANTHROPIC_SMALL_FAST_MODEL="openai/gpt-3.5-turbo"
                ;;
            *)
                # Use as-is if it's an OpenRouter model ID
                export ANTHROPIC_MODEL="$model_name"
                export ANTHROPIC_SMALL_FAST_MODEL="$model_name"
                ;;
        esac

        echo -e "${GREEN}✅ $(t 'switched_to') OpenRouter (${model_name})${NC}"
    else
        echo -e "${RED}❌ Please configure OPENROUTER_API_KEY${NC}"
        return 1
    fi
}
```

#### 1.3 Add OpenRouter to Command Routing

**Location**: `ccm.sh` - `main()` function

Add to the case statement:
```bash
openrouter|or)
    switch_to_openrouter "$2"
    emit_env_exports
    ;;
```

#### 1.4 Add OpenRouter to CCC Command

**Location**: `ccc` script

Add support for:
- `ccc openrouter` (launch with default model)
- `ccc openrouter sonnet` (launch with specific model)
- `ccc or gpt4` (shortcut with model selection)

### Phase 2: Model Management

#### 2.1 Create OpenRouter Model Mapping

**Location**: `ccm.sh` - new function

```bash
get_openrouter_model_id() {
    local alias="$1"
    case "$alias" in
        "sonnet") echo "anthropic/claude-3.5-sonnet" ;;
        "opus") echo "anthropic/claude-3-opus" ;;
        "haiku") echo "anthropic/claude-3-haiku" ;;
        "gpt4") echo "openai/gpt-4-turbo" ;;
        "gpt3.5") echo "openai/gpt-3.5-turbo" ;;
        "gemini") echo "google/gemini-pro" ;;
        "llama") echo "meta-llama/llama-3-70b-instruct" ;;
        "mixtral") echo "mistralai/mixtral-8x7b-instruct" ;;
        *) echo "$alias" ;;  # Return as-is if no mapping
    esac
}
```

#### 2.2 Add Popular OpenRouter Models Support

Add shortcuts for popular OpenRouter models:
- DeepSeek models: `ccc or deepseek`
- Llama models: `ccc or llama`
- Gemini models: `ccc or gemini`
- Mistral models: `ccc or mixtral`

#### 2.3 Interactive Model Selection

**Location**: `ccm.sh` - new function

```bash
list_openrouter_models() {
    echo "🤖 Available OpenRouter models:"
    echo "   Claude Models:"
    echo "     - sonnet (claude-3.5-sonnet)"
    echo "     - opus (claude-3-opus)"
    echo "     - haiku (claude-3-haiku)"
    echo "   OpenAI Models:"
    echo "     - gpt4 (gpt-4-turbo)"
    echo "     - gpt3.5 (gpt-3.5-turbo)"
    echo "   Other Popular Models:"
    echo "     - gemini (google/gemini-pro)"
    echo "     - llama (meta-llama/llama-3-70b-instruct)"
    echo "     - mixtral (mistralai/mixtral-8x7b-instruct)"
    echo "     - deepseek (deepseek/deepseek-coder)"
}
```

### Phase 3: Configuration Enhancement

#### 3.1 Add OpenRouter to Configuration Template

**Location**: `ccm.sh` - `show_config_template()` function

Add OpenRouter section with popular models:
```bash
# OpenRouter - Access to 100+ models with one API key
OPENROUTER_API_KEY=sk-or-v1-your-openrouter-api-key

# Optional: specify default models
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
OPENROUTER_SMALL_FAST_MODEL=openai/gpt-4o-mini
```

#### 3.2 Environment Variable Support

Ensure OpenRouter respects environment variables:
```bash
export OPENROUTER_API_KEY=sk-or-v1-xxx
export OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
```

#### 3.3 Add to Help Text

**Location**: `ccm.sh` - `show_help()` function

Add OpenRouter usage examples:
```
OpenRouter Commands:
  ccm openrouter [model]    Switch to OpenRouter (default: claude-3.5-sonnet)
  ccm or [model]          Shortcut for openrouter
```

### Phase 4: Documentation

#### 4.1 Update README.md

**Tasks**:
- [ ] Add OpenRouter to supported models table
- [ ] Add OpenRouter registration link and benefits
- [ ] Update usage examples with OpenRouter commands
- [ ] Add OpenRouter configuration instructions

#### 4.2 Create OpenRouter Guide

**New File**: `docs/OPENROUTER_GUIDE.md`

Content to include:
- OpenRouter benefits and features
- Account setup and API key retrieval
- Available models and pricing
- Usage examples and best practices
- Troubleshooting common issues

#### 4.3 Update Translations

**Files**: `lang/en.json`, `lang/zh.json`

Add translation keys:
```json
{
  "openrouter": "OpenRouter",
  "openrouter_desc": "Unified access to 100+ AI models",
  "switched_to_openrouter": "Switched to OpenRouter",
  "openrouter_api_key_not_detected": "OpenRouter API key not detected"
}
```

### Phase 5: Testing

#### 5.1 Unit Tests

**Location**: `test/` directory (create if not exists)

Create `test_openrouter.sh`:
```bash
#!/bin/bash
# Test OpenRouter integration

# Test 1: Configuration loading
source ../ccm.sh
# Test OPENROUTER_API_KEY detection

# Test 2: Model switching
# Test switch_to_openrouter with various models

# Test 3: Model mapping
# Test get_openrouter_model_id function

# Test 4: Environment exports
# Verify correct ANTHROPIC_* variables are set
```

#### 5.2 Integration Tests

**New File**: `test_install_openrouter.sh`

Test full workflow:
1. Install CCM with OpenRouter support
2. Configure OpenRouter API key
3. Switch to OpenRouter models
4. Launch Claude Code
5. Verify functionality

#### 5.3 Manual Testing Checklist

- [ ] API key validation works correctly
- [ ] Model switching functions properly
- [ ] All model aliases resolve correctly
- [ ] CCC command launches with OpenRouter
- [ ] Error handling for missing API key
- [ ] Status display shows OpenRouter correctly

### Phase 6: Advanced Features (Future)

#### 6.1 Model Cost Tracking

Add cost estimation features:
- Track token usage per model
- Show cost estimates before switching
- Monthly spending summaries

#### 6.2 Dynamic Model List

Fetch available models from OpenRouter API:
```bash
fetch_openrouter_models() {
    curl -s -H "Authorization: Bearer $OPENROUTER_API_KEY" \
         https://openrouter.ai/api/v1/models
}
```

#### 6.3 Model Performance Metrics

Add model performance information:
- Response time averages
- Reliability scores
- User ratings integration

## Implementation Priority

1. **High Priority**: Phase 1-2 (Core integration and model management)
2. **Medium Priority**: Phase 3-4 (Configuration and documentation)
3. **Low Priority**: Phase 5-6 (Testing and advanced features)

## Files to Modify

1. `ccm.sh` - Main implementation
2. `ccc` - Launcher script updates
3. `README.md` - Documentation
4. `README_CN.md` - Chinese documentation
5. `lang/en.json` - English translations
6. `lang/zh.json` - Chinese translations
7. `install.sh` - Installation script (if needed)

## New Files to Create

1. `docs/OPENROUTER_GUIDE.md` - OpenRouter specific guide
2. `test/test_openrouter.sh` - Unit tests
3. `test_install_openrouter.sh` - Integration tests

## API Reference

### OpenRouter API Endpoints

- **Base URL**: `https://openrouter.ai/api/v1`
- **Models List**: `https://openrouter.ai/api/v1/models`
- **Chat Completions**: `https://openrouter.ai/api/v1/chat/completions`

### Authentication

```bash
# Header format
Authorization: Bearer $OPENROUTER_API_KEY

# Environment variable
export OPENROUTER_API_KEY=sk-or-v1-xxxxxxxx
```

### Model ID Format

OpenRouter uses provider/model format:
- `anthropic/claude-3.5-sonnet`
- `openai/gpt-4-turbo`
- `google/gemini-pro`
- `meta-llama/llama-3-70b-instruct`

## Security Considerations

1. **API Key Protection**: Treat OpenRouter API keys like any other API key
2. **Access Control**: Implement proper access logging and rate limiting
3. **Cost Management**: Warn users about potential costs
4. **Privacy**: Ensure no sensitive data is logged

## Timeline Estimate

- **Phase 1**: 2-3 hours
- **Phase 2**: 1-2 hours
- **Phase 3**: 1 hour
- **Phase 4**: 2-3 hours
- **Phase 5**: 2-3 hours
- **Phase 6**: Future work

**Total Estimated Time**: 8-12 hours for full implementation

## Success Metrics

1. ✅ Users can switch to OpenRouter with `ccm openrouter`
2. ✅ Multiple model aliases work correctly
3. ✅ CCC command launches Claude Code with OpenRouter
4. ✅ Documentation is comprehensive and clear
5. ✅ Tests pass for all functionality
6. ✅ No regression in existing functionality

## Next Steps

1. Review and approve this plan
2. Create development branch for OpenRouter feature
3. Begin Phase 1 implementation
4. Test each phase before proceeding
5. Merge after complete testing and review