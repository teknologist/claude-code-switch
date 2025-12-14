# Claude Code Model Switcher (CCM) 🔧

> A powerful Claude Code model switching tool with support for multiple AI service providers and intelligent fallback mechanisms

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)](https://github.com/foreveryh/claude-code-switch)

[中文文档](README_CN.md) | [English](README.md)

## 🔄 Changes from Original Project

This is a fork of the original [claude-code-switch](https://github.com/foreveryh/claude-code-switch) with the following significant modifications:

### Removed PPInfra Integration
- ❌ **Removed all PPInfra fallback functionality** - The backup service integration has been completely removed
- ❌ **Deleted PPInfra-related configuration options** - `PPINFRA_API_KEY` and associated settings removed
- ❌ **Removed PPInfra commands** - No more `ccm pp` or `ccc pp` commands
- ❌ **Deleted PPINFRA_USAGE.md** - Documentation for PPInfra service removed
- ❌ **Simplified model switching logic** - Removed fallback branching logic that checked for PPInfra keys

### Security Improvements
- ✅ **Enhanced input validation** - Improved validation for API keys and configuration
- ✅ **Fixed 7 security vulnerabilities** - Addressed potential security issues in the codebase
- ✅ **Cleaner configuration management** - Streamlined config without fallback complexity

### Model Updates
- ✅ **Added Claude Haiku 4.5 support** - Latest fast model from Anthropic
- ✅ **Updated Claude Opus to 4.5** - Upgraded from Opus 4.1 to 4.5
- ✅ **Added Doubao Seed-Code model** - New code-optimized model from Volcano Engine

### Key Differences in Usage
- Model switching now requires official API keys only
- No backup service fallbacks available
- Cleaner, more straightforward configuration
- Enhanced security posture

---

## 🎯 Quick Start (Zero Configuration)

Want to try immediately **without any API key**? Start in 3 steps:

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/foreveryh/claude-code-switch/main/quick-install.sh | bash

# 2. Reload shell
source ~/.zshrc  # or source ~/.bashrc for bash

# 3. Try it (no keys needed!)
ccm glm          # Switch to GLM-4.6
ccc deepseek     # Launch Claude Code with DeepSeek
```

✨ **That's it!** You now have a working Claude Code setup with:
- ✅ Multiple model support
- ✅ Easy configuration management
- ✅ Add your own API keys for full functionality
- ⚠️ **Note**: This version requires official API keys for each provider

## 🌟 Features

- 🤖 **Multi-model Support**: Claude, Deepseek, KIMI, GLM, Qwen and other mainstream AI models
- ⚡ **Quick Switching**: One-click switching between different AI models to boost productivity
- 🚀 **One-Command Launch**: `ccc` command switches model and launches Claude Code in a single step
- 🎨 **Colorful Interface**: Intuitive command-line interface with clear switching status display
- 🛡️ **Secure Configuration**: Independent configuration file for API key management
- 📊 **Status Monitoring**: Real-time display of current model configuration and key status

## 📦 Supported Models

| Model | Model ID | Provider | Features |
|-------|----------|----------|----------|
| 🌙 **KIMI for Coding** | kimi-for-coding | Moonshot AI | Official coding version |
| 🌕 **KIMI CN** | kimi-k2-thinking | Moonshot AI | China domestic version |
| 🤖 **Deepseek** | deepseek-chat | DeepSeek | Cost-effective reasoning |
| 🌰 **Doubao Seed-Code** | doubao-seed-code-preview-latest | Volcano Engine | Code-optimized |
| 🐱 **LongCat** | LongCat-Flash-Chat | LongCat | High-speed chat |
| 🎯 **MiniMax M2** | MiniMax-M2 | MiniMax | Code & reasoning |
| 🌊 **StreamLake (KAT)** | KAT-Coder | StreamLake | AI coding assistant |
| 🐪 **Qwen** | qwen3-max | Alibaba DashScope | Alibaba Cloud |
| 🇨🇳 **GLM4.6** | glm-4.6 | Zhipu AI | Zhipu AI |
| 🧠 **Claude Sonnet 4.5** | claude-sonnet-4-5-20250929 | Anthropic | Balanced performance |
| 🚀 **Claude Opus 4.5** | claude-opus-4-5-20251101 | Anthropic | Strongest reasoning |
| 🔷 **Claude Haiku 4.5** | claude-haiku-4-5 | Anthropic | Fast and efficient |

> 🎁 **GLM-4.6 Official Registration**
>
> Get started with Zhipu AI's official Claude Code integration:
> - **Registration Link**: https://www.bigmodel.cn/claude-code?ic=5XMIOZPPXB
> - **Invitation Code**: `5XMIOZPPXB`
>
> GLM-4.6 supports official Claude Code integration with zero-configuration experience.

## 🛠️ Installation

### Method 1: Quick Install (Recommended) ⚡

One-command installation from GitHub - no cloning required:

```bash
curl -fsSL https://raw.githubusercontent.com/foreveryh/claude-code-switch/main/quick-install.sh | bash
source ~/.zshrc  # reload shell
```

**Features:**
- ✅ No cloning needed
- ✅ Automatic file download from GitHub
- ✅ Retry mechanism for network failures
- ✅ File integrity verification
- ✅ Progress feedback and error handling

### Method 2: Local Install (For Development)

Clone the repository and install locally:

```bash
git clone https://github.com/foreveryh/claude-code-switch.git
cd claude-code-switch
chmod +x install.sh ccm.sh
./install.sh
source ~/.zshrc  # reload shell
```

**Without installation** (run from cloned directory):
```bash
./ccc deepseek                   # Launch with DeepSeek (current process only)
eval "$(./ccm env deepseek)"    # Set env vars in current shell only
```

### What Gets Installed?

The installation process:
- Copies `ccm.sh` to `~/.local/share/ccm/ccm.sh`
- Copies language files to `~/.local/share/ccm/lang/`
- Injects `ccm()` and `ccc()` shell functions into your rc file (~/.zshrc or ~/.bashrc)
- Creates `~/.ccm_config` on first use (if it doesn't exist)

**Does NOT:**
- Modify system files
- Change your PATH
- Require sudo/root access
- Affect other shell configurations

## ⚙️ Configuration

### 🔑 Configuration Priority

CCM uses a hierarchical configuration system:

1. **Environment Variables** (Highest Priority)
   ```bash
   export DEEPSEEK_API_KEY=sk-your-key
   export KIMI_API_KEY=your-key
   export GLM_API_KEY=your-key
   export QWEN_API_KEY=your-key
   ```

2. **Configuration File** `~/.ccm_config` (Fallback)
   ```bash
   ccm config              # Opens config in your editor
   # Or edit manually: vim ~/.ccm_config
   ```

### Configuration File Example

```bash
# CCM Configuration File
# Note: Environment variables take priority over this file

# Official API keys
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
KIMI_API_KEY=your-kimi-api-key  # Moonshot AI
LONGCAT_API_KEY=your-longcat-api-key
MINIMAX_API_KEY=your-minimax-api-key
GLM_API_KEY=your-glm-api-key
QWEN_API_KEY=your-qwen-api-key  # Alibaba Cloud DashScope

# Optional: override model IDs (if omitted, defaults are used)
DEEPSEEK_MODEL=deepseek-chat
KIMI_MODEL=kimi-for-coding  # For KIMI for Coding
KIMI_CN_MODEL=kimi-k2-thinking  # For KIMI CN (domestic version)
LONGCAT_MODEL=LongCat-Flash-Thinking
MINIMAX_MODEL=MiniMax-M2
QWEN_MODEL=qwen3-max
GLM_MODEL=glm-4.6
CLAUDE_MODEL=claude-sonnet-4-5-20250929
OPUS_MODEL=claude-opus-4-5-20251101
```

**Security Note:** Recommend `chmod 600 ~/.ccm_config` to protect your API keys.

## 🔐 Claude Pro Account Management (NEW in v2.2.0)

CCM now supports managing multiple Claude Pro subscription accounts! Switch between accounts to bypass usage limits without upgrading to Claude Max.

### Why Use Multiple Accounts?

- **Bypass Usage Limits**: Each Claude Pro account has its own usage limits (5 hours per day, weekly caps)
- **Cost-Effective**: Multiple Pro accounts are cheaper than one Max account
- **Seamless Switching**: No need to log out/in - CCM handles authentication automatically
- **Secure Storage**: Account credentials stored securely in macOS Keychain with local backup

### Account Management Commands

```bash
# Save current logged-in account
ccm save-account work              # Save as "work"
ccm save-account personal          # Save as "personal"

# Switch between accounts
ccm switch-account work            # Switch to work account
ccm switch-account personal        # Switch to personal account

# View all saved accounts
ccm list-accounts
# Output:
# 📋 Saved Claude Pro accounts:
#   - work (Pro, expires: 2025-12-31, ✅ active)
#   - personal (Pro, expires: 2025-12-31)

# Check current account
ccm current-account

# Delete saved account
ccm delete-account old-account
```

### Quick Account Switching with Models

```bash
# Switch account and select model in one command
ccm opus:work                      # Switch to work account, use Opus
ccm haiku:personal                 # Switch to personal account, use Haiku
ccc opus:work                      # Switch account and launch Claude Code
ccc woohelps                       # Switch to 'woohelps' account and launch (default model)
```

### Account Setup Guide

**Step 1**: Save your first account
```bash
# Login to Claude Code with account 1 in browser
# Launch Claude Code to verify it works
ccm save-account account1
```

**Step 2**: Save additional accounts
```bash
# Quit Claude Code
# Logout from claude.ai in browser
# Login with account 2
# Launch Claude Code again
ccm save-account account2
```

**Step 3**: Switch between accounts anytime
```bash
ccm switch-account account1        # No browser login needed!
# Restart Claude Code for changes to take effect
```

**Important Notes**:
- Tokens are refreshed automatically - no re-login needed until they expire
- After switching accounts, restart Claude Code for changes to take effect
- Account credentials are primarily stored in macOS Keychain (most secure)
- Local backup stored in `~/.ccm_accounts` with base64 encoding and chmod 600 permissions
- Credentials persist across system reboots
- Keychain service name defaults to `Claude Code-credentials`. Override via `CCM_KEYCHAIN_SERVICE` if your system uses a different name

**Security Considerations**:
- Always use `chmod 600 ~/.ccm_accounts` to protect your local backup
- The system relies on macOS Keychain for secure credential storage
- Local backup uses base64 encoding (not encryption) for compatibility

### Debugging Keychain

```bash
ccm debug-keychain                # Inspect current Keychain credentials and match saved accounts
# If it shows no credentials but you are logged in, set service override:
CCM_KEYCHAIN_SERVICE="Claude Code" ccm debug-keychain
```

### Troubleshooting Account Management

**Problem**: "No credentials found in Keychain"
- Solution: Make sure you're logged into Claude Code in your browser or IDE
- Try different keychain service names with `CCM_KEYCHAIN_SERVICE` environment variable

**Problem**: "Account switching doesn't work"
- Solution: Restart Claude Code after switching accounts
- Check that the account exists with `ccm list-accounts`

**Problem**: "Permission denied accessing accounts file"
- Solution: Run `chmod 600 ~/.ccm_accounts` to fix permissions

**Problem**: "JSON format error in accounts file"
- Solution: Delete `~/.ccm_accounts` and re-save your accounts

## 📖 Usage

### Two Ways to Use CCM

**Method 1: `ccm` - Environment Management**
```bash
ccm deepseek      # Switch to DeepSeek
ccm glm           # Switch to GLM4.6
ccm kimi          # Switch to KIMI
claude            # Then manually launch Claude Code
```

**Method 2: `ccc` - One-Command Launch (Recommended)**
```bash
ccc deepseek                            # Switch and launch
ccc glm                                 # Switch and launch
ccc kimi --dangerously-skip-permissions # Pass options to Claude Code
```

### Basic Commands

```bash
# Switch to different models
ccm kimi          # Switch to KIMI for Coding (official coding version)
ccm kimi-cn       # Switch to KIMI CN (China domestic version)
ccm deepseek      # Switch to Deepseek
ccm seed          # Switch to Doubao Seed-Code
ccm minimax       # Switch to MiniMax M2
ccm qwen          # Switch to Qwen
ccm kat           # Switch to StreamLake (KAT)
ccm glm           # Switch to GLM4.6
ccm longcat       # Switch to LongCat
ccm claude        # Switch to Claude Sonnet 4.5
ccm opus          # Switch to Claude Opus 4.5
ccm haiku         # Switch to Claude Haiku 4.5


# Launch Claude Code
ccc deepseek      # Switch to DeepSeek and launch
ccc seed          # Switch to Seed-Code and launch
ccc glm           # Switch to GLM and launch
ccc opus          # Switch to Claude Opus and launch
ccc kat           # Switch to StreamLake (KAT) and launch

# Utility commands
ccm status        # View current status (masked)
ccm config        # Edit configuration
ccm help          # Show help
ccc               # Show ccc usage help
```

### Command Shortcuts

```bash
# ccm shortcuts
ccm ds           # Short for deepseek
ccm mm           # Short for minimax
ccm s            # Short for claude sonnet
ccm o            # Short for opus (Claude Opus 4.5)
ccm h            # Short for haiku
ccm st           # Short for status

# ccc shortcuts
ccc ds           # Launch with DeepSeek
ccc kat          # Launch with StreamLake (KAT)
```

### Usage Examples

**Example 1: Zero configuration (built-in keys)**
```bash
ccc deepseek
🔄 Switching to deepseek...
✅ Environment configured for: DeepSeek

🚀 Launching Claude Code...
   Model: deepseek-chat
   Base URL: https://api.ppinfra.com/anthropic
```

**Example 2: With your own API keys**
```bash
export KIMI_API_KEY=your-moonshot-key
ccm kimi
ccm status
📊 Current model configuration:
   BASE_URL: https://api.moonshot.cn/anthropic
   AUTH_TOKEN: [Set]
   MODEL: kimi-k2-turbo-preview
   SMALL_MODEL: kimi-k2-turbo-preview

claude  # Launch manually
```

**Example 3: One-command launch**
```bash
ccc glm --dangerously-skip-permissions
🔄 Switching to GLM...
✅ Environment configured for: GLM

🚀 Launching Claude Code...
   Model: glm-4.6
   Base URL: https://api.z.ai/api/anthropic
```

## 🔧 Advanced Features

### Service Integrations

**Alibaba Cloud DashScope** (Qwen models):
- Base URL: `https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy`
- Default Models: `qwen3-max` (primary), `qwen3-next-80b-a3b-instruct` (fast)
- API Key Format: Standard `sk-` prefix from Alibaba Cloud console

**Model-specific Endpoints**:
- Each model provider uses their official API endpoint
- Configuration is simplified - no fallback services needed
- Direct API communication ensures best performance and reliability

### Security and Privacy

- Status output masks secrets (shows only first/last 4 chars)
- CCM sets only `ANTHROPIC_AUTH_TOKEN` (not `ANTHROPIC_API_KEY`)
- Configuration file precedence: Environment Variables > ~/.ccm_config
- Recommended file permission: `chmod 600 ~/.ccm_config`

## 🗑️ Uninstall

```bash
# If installed via quick-install.sh or install.sh
./uninstall.sh

# Or manually:
# 1. Remove the ccm/ccc function blocks from ~/.zshrc or ~/.bashrc
# 2. Delete the installation directory
rm -rf ~/.local/share/ccm
rm ~/.ccm_config  # optional: remove config file
```

## 🐛 Troubleshooting

### Common Issues

**Q: Getting "XXX_API_KEY not detected" error**
```bash
A: Check if the API key is correctly configured:
   ccm config      # Open config file to check
   ccm status      # View current configuration
```

**Q: Claude Code doesn't work after switching**
```bash
A: Verify environment variables:
   ccm status                   # Check current status
   echo $ANTHROPIC_BASE_URL     # Check environment variable
   env | grep ANTHROPIC         # List all ANTHROPIC vars
```

**Q: Want to use official service instead of fallback**
```bash
A: Configure the official API key, CCM will automatically prioritize it:
   export DEEPSEEK_API_KEY=sk-your-official-key
   ccm deepseek
```

**Q: Auth conflict about API_KEY vs AUTH_TOKEN**
```bash
A: CCM only sets ANTHROPIC_AUTH_TOKEN, unset any conflicting variable:
   unset ANTHROPIC_API_KEY
```

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Development Setup
```bash
git clone https://github.com/foreveryh/claude-code-switch.git
cd claude-code-switch
```

### Commit Guidelines
- Use clear commit messages
- Add appropriate tests
- Update documentation

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Claude](https://claude.ai) - AI Assistant
- [Deepseek](https://deepseek.com) - Efficient reasoning model
- [KIMI](https://kimi.moonshot.cn) - Long text processing
- [MiniMax](https://www.minimaxi.com) - MiniMax M2 model
- [Zhipu AI](https://zhipuai.cn) - GLM large model
- [Qwen](https://qwen.alibaba.com) - Alibaba Tongyi Qianwen
- [Doubao](https://www.volcengine.com/product/ark) - Doubao Seed-Code

---

⭐ If this project helps you, please give it a Star!

📧 Questions or suggestions? Feel free to submit an [Issue](https://github.com/foreveryh/claude-code-switch/issues)
