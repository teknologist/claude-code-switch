#!/bin/bash
############################################################
# Claude Code Model Switcher (ccm) - Standalone Version
# ---------------------------------------------------------
# Function: Quickly switch between different AI models
# Supports: Claude, Deepseek, GLM4.6, KIMI2
# Author: Peng
# Version: 2.2.0
############################################################

# Script color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Color control (for account management command output)
NO_COLOR=${NO_COLOR:-false}

# Set colors based on NO_COLOR (used by account management functions)
set_no_color() {
    if [[ "$NO_COLOR" == "true" ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        NC=''
    fi
}

# Config file paths
CONFIG_FILE="$HOME/.ccm_config"
ACCOUNTS_FILE="$HOME/.ccm_accounts"
# Keychain service name (override with CCM_KEYCHAIN_SERVICE)
KEYCHAIN_SERVICE="${CCM_KEYCHAIN_SERVICE:-Claude Code-credentials}"

# Multi-language support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LANG_DIR="$SCRIPT_DIR/lang"

# Load translations
load_translations() {
    local lang_code="${1:-en}"

    # SECURITY FIX (MEDIUM-003): Validate language code to prevent path traversal
    case "$lang_code" in
        en|zh) ;;
        *) lang_code="en" ;;
    esac

    local lang_file="$LANG_DIR/${lang_code}.json"

    # If language file doesn't exist, default to English
    if [[ ! -f "$lang_file" ]]; then
        lang_code="en"
        lang_file="$LANG_DIR/en.json"
    fi

    # If English file also doesn't exist, use built-in English
    if [[ ! -f "$lang_file" ]]; then
        return 0
    fi

    # Clean existing translation variables
    unset $(set | grep '^TRANS_' | LC_ALL=C cut -d= -f1) 2>/dev/null || true

    # Read JSON file and parse into variables
    if [[ -f "$lang_file" ]]; then
        local temp_file
        temp_file=$(mktemp -t ccm_trans.XXXXXX) || return 1
        chmod 600 "$temp_file"
        # Ensure cleanup on exit/interrupt
        trap 'rm -f "$temp_file" 2>/dev/null' RETURN

        # Extract key-value pairs to temp file using robust method
        grep -o '"[^"]*":[[:space:]]*"[^"]*"' "$lang_file" | sed 's/^"\([^"]*\)":[[:space:]]*"\([^"]*\)"$/\1|\2/' > "$temp_file"

        # Read temp file and set variables (using TRANS_ prefix)
        while IFS='|' read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                # SECURITY FIX (HIGH-001): Validate key contains only safe characters
                if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    continue  # Skip invalid keys
                fi
                # Process escape characters
                value="${value//\\\"/\"}"
                value="${value//\\\\/\\}"
                # Use printf and declare for safer variable assignment (avoid eval injection)
                printf -v "TRANS_${key}" '%s' "$value"
            fi
        done < "$temp_file"
        # Note: temp_file cleanup handled by trap on RETURN
    fi
}

# Get translated text
t() {
    local key="$1"
    local default="${2:-$key}"
    # SECURITY FIX (HIGH-001): Validate key before variable lookup
    if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "$default"
        return
    fi
    local var_name="TRANS_${key}"
    # Use indirect expansion instead of eval for safer variable lookup
    local value="${!var_name:-}"
    echo "${value:-$default}"
}

# Detect system language
detect_language() {
    # First check LANG environment variable
    local sys_lang="${LANG:-}"
    if [[ "$sys_lang" =~ ^zh ]]; then
        echo "zh"
    else
        echo "en"
    fi
}

# Smart config loading: environment variables take priority, config file supplements
load_config() {
    # Initialize language
    local lang_preference="${CCM_LANGUAGE:-$(detect_language)}"
    load_translations "$lang_preference"

    # Create config file (if not exists)
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
# CCM Configuration File
# Please replace with your actual API keys
# Note: API keys in environment variables take priority over this file

# Language setting (en: English, zh: Chinese)
CCM_LANGUAGE=en

# Deepseek
DEEPSEEK_API_KEY=sk-your-deepseek-api-key

# GLM4.6 (Zhipu)
GLM_API_KEY=your-glm-api-key

# KIMI for Coding (Moonshot)
KIMI_API_KEY=your-kimi-api-key

# LongCat (Meituan)
LONGCAT_API_KEY=your-longcat-api-key

# MiniMax M2
MINIMAX_API_KEY=your-minimax-api-key

# Doubao Seed-Code (ByteDance)
ARK_API_KEY=your-ark-api-key

# Qwen (Alibaba DashScope)
QWEN_API_KEY=your-qwen-api-key

# Claude (if using API key instead of Pro subscription)
CLAUDE_API_KEY=your-claude-api-key

# -- Optional: Model ID overrides (defaults below if not set) --
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat
KIMI_MODEL=kimi-for-coding
KIMI_SMALL_FAST_MODEL=kimi-for-coding
KIMI_CN_MODEL=kimi-k2-thinking
KIMI_CN_SMALL_FAST_MODEL=kimi-k2-thinking
QWEN_MODEL=qwen3-max
QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-instruct
GLM_MODEL=glm-4.6
GLM_SMALL_FAST_MODEL=glm-4.5-air
CLAUDE_MODEL=claude-sonnet-4-5-20250929
CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929
OPUS_MODEL=claude-opus-4-5-20251101
OPUS_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929
HAIKU_MODEL=claude-haiku-4-5
HAIKU_SMALL_FAST_MODEL=claude-haiku-4-5
LONGCAT_MODEL=LongCat-Flash-Thinking
LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat
MINIMAX_MODEL=MiniMax-M2
MINIMAX_SMALL_FAST_MODEL=MiniMax-M2
SEED_MODEL=doubao-seed-code-preview-latest
SEED_SMALL_FAST_MODEL=doubao-seed-code-preview-latest

EOF
        # SECURITY FIX (LOW-001): Set restrictive permissions on config file
        chmod 600 "$CONFIG_FILE"
        echo -e "${YELLOW}⚠️  $(t 'config_created'): $CONFIG_FILE${NC}" >&2
        echo -e "${YELLOW}   $(t 'edit_file_to_add_keys')${NC}" >&2
        echo -e "${GREEN}🚀 Using default experience keys for now...${NC}" >&2
        # Don't return 1 - continue with default fallback keys
    fi

    # First read language setting
    if [[ -f "$CONFIG_FILE" ]]; then
        local config_lang
        config_lang=$(grep -E "^[[:space:]]*CCM_LANGUAGE[[:space:]]*=" "$CONFIG_FILE" 2>/dev/null | head -1 | LC_ALL=C cut -d'=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        if [[ -n "$config_lang" && -z "$CCM_LANGUAGE" ]]; then
            export CCM_LANGUAGE="$config_lang"
            lang_preference="$config_lang"
            load_translations "$lang_preference"
        fi
    fi

    # Smart loading: only load from config file if env var not set
    # SECURITY FIX (MEDIUM-001): Secure temp file handling
    local temp_file
    temp_file=$(mktemp -t ccm_config.XXXXXX) || return 1
    chmod 600 "$temp_file"
    trap 'rm -f "$temp_file" 2>/dev/null' RETURN

    local raw
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        # Remove carriage return, inline comments and trim whitespace
        raw=${raw%$'\r'}
        # Skip comments and empty lines
        [[ "$raw" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$raw" ]] && continue
        # Remove inline comments (from first #)
        local line="${raw%%#*}"
        # Trim leading/trailing whitespace
        line=$(echo "$line" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [[ -z "$line" ]] && continue

        # Parse export KEY=VALUE or KEY=VALUE
        if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]]; then
            local key="${BASH_REMATCH[2]}"
            local value="${BASH_REMATCH[3]}"
            # Trim leading/trailing whitespace
            value=$(echo "$value" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//')
            # Only apply if env not set, empty, or placeholder
            local env_value="${!key}"
            local lower_env_value
            lower_env_value=$(printf '%s' "$env_value" | tr '[:upper:]' '[:lower:]')
            # Check if placeholder value
            local is_placeholder=false
            if [[ "$lower_env_value" == *"your"* && "$lower_env_value" == *"api"* && "$lower_env_value" == *"key"* ]]; then
                is_placeholder=true
            fi
            if [[ -n "$key" && ( -z "$env_value" || "$env_value" == "" || "$is_placeholder" == "true" ) ]]; then
                echo "export $key=$value" >> "$temp_file"
            fi
        fi
    done < "$CONFIG_FILE"

    # Execute export statements from temp file
    if [[ -s "$temp_file" ]]; then
        source "$temp_file"
    fi
    # Note: temp_file cleanup handled by RETURN trap
}

# Create default config file
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# CCM Configuration File
# Please replace with your actual API keys
# Note: API keys in environment variables take priority over this file

# Language setting (en: English, zh: Chinese)
CCM_LANGUAGE=en

# Deepseek
DEEPSEEK_API_KEY=sk-your-deepseek-api-key

# GLM4.6 (Zhipu)
GLM_API_KEY=your-glm-api-key

# KIMI for Coding (Moonshot)
KIMI_API_KEY=your-kimi-api-key

# LongCat (Meituan)
LONGCAT_API_KEY=your-longcat-api-key

# MiniMax M2
MINIMAX_API_KEY=your-minimax-api-key

# Doubao Seed-Code (ByteDance)
ARK_API_KEY=your-ark-api-key

# Qwen (Alibaba DashScope)
QWEN_API_KEY=your-qwen-api-key

# Claude (if using API key instead of Pro subscription)
CLAUDE_API_KEY=your-claude-api-key

# -- Optional: Model ID overrides (defaults below if not set) --
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat
KIMI_MODEL=kimi-for-coding
KIMI_SMALL_FAST_MODEL=kimi-for-coding
KIMI_CN_MODEL=kimi-k2-thinking
KIMI_CN_SMALL_FAST_MODEL=kimi-k2-thinking
QWEN_MODEL=qwen3-max
QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-instruct
GLM_MODEL=glm-4.6
GLM_SMALL_FAST_MODEL=glm-4.5-air
CLAUDE_MODEL=claude-sonnet-4-5-20250929
CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929
OPUS_MODEL=claude-opus-4-5-20251101
OPUS_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929
HAIKU_MODEL=claude-haiku-4-5
HAIKU_SMALL_FAST_MODEL=claude-haiku-4-5
LONGCAT_MODEL=LongCat-Flash-Thinking
LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat
MINIMAX_MODEL=MiniMax-M2
MINIMAX_SMALL_FAST_MODEL=MiniMax-M2
SEED_MODEL=doubao-seed-code-preview-latest
SEED_SMALL_FAST_MODEL=doubao-seed-code-preview-latest

EOF
    # SECURITY FIX (LOW-001): Set restrictive permissions on config file
    chmod 600 "$CONFIG_FILE"
    echo -e "${YELLOW}⚠️  $(t 'config_created'): $CONFIG_FILE${NC}" >&2
    echo -e "${YELLOW}   $(t 'edit_file_to_add_keys')${NC}" >&2
}

# Check if value is valid (non-empty and not placeholder)
is_effectively_set() {
    local v="$1"
    if [[ -z "$v" ]]; then
        return 1
    fi
    local lower
    lower=$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        *your-*-api-key)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Secure masking utility
mask_token() {
    local t="$1"
    local n=${#t}
    if [[ -z "$t" ]]; then
        echo "[$(t 'not_set')]"
        return
    fi
    if (( n <= 8 )); then
        echo "[$(t 'set')] ****"
    else
        echo "[$(t 'set')] ${t:0:4}...${t:n-4:4}"
    fi
}

mask_presence() {
    local v_name="$1"
    local v_val="${!v_name}"
    if is_effectively_set "$v_val"; then
        echo "[$(t 'set')]"
    else
        echo "[$(t 'not_set')]"
    fi
}

# ============================================
# Security Helper Functions
# ============================================

# Escape special regex characters in a string for safe use in grep patterns
# This prevents dots and other special chars from being interpreted as regex
escape_for_regex() {
    printf '%s' "$1" | sed 's/[.[\*^$()+?{|\\]/\\&/g'
}

# SECURITY FIX (LOW-002): Sanitize user input for safe display
# Removes control characters and ANSI escape sequences
sanitize_for_display() {
    local input="$1"
    local max_len="${2:-100}"
    # Remove ANSI escape sequences (comprehensive) and control characters except tab/newline
    local sanitized
    # Remove: CSI sequences, OSC sequences (terminal title etc), and other escape sequences
    sanitized=$(printf '%s' "$input" | tr -d '\000-\010\013-\037\177' | \
        sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' \
            -e 's/\x1b\][^\x07]*\x07//g' \
            -e 's/\x1b[PX^_][^\x1b]*\x1b\\//g' \
            -e 's/\x1b.//g')
    # Truncate if too long
    if [[ ${#sanitized} -gt $max_len ]]; then
        sanitized="${sanitized:0:$max_len}..."
    fi
    printf '%s' "$sanitized"
}

# ============================================
# Claude Pro 账号管理功能
# ============================================

# SECURITY FIX (HIGH-002): Validate account name to prevent command injection
# Only allows alphanumeric characters, hyphens, underscores, and dots
validate_account_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    # Allow only safe characters: letters, numbers, hyphens, underscores, dots
    # Must start with letter or number
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        # SECURITY FIX (LOW-002): Sanitize input before displaying
        echo -e "${RED}❌ Invalid account name: '$(sanitize_for_display "$name" 50)'${NC}" >&2
        echo -e "${YELLOW}$(t 'invalid_account_name_format')${NC}" >&2
        return 1
    fi
    # Limit length to prevent issues
    if [[ ${#name} -gt 64 ]]; then
        echo -e "${RED}❌ $(t 'account_name_too_long')${NC}" >&2
        return 1
    fi
    return 0
}

# Global variable to store the keychain account name
KEYCHAIN_ACCOUNT=""

# 从 macOS Keychain 读取 Claude Code 凭证
read_keychain_credentials() {
    local credentials
    local -a services=(
        "$KEYCHAIN_SERVICE"
        "Claude Code - credentials"
        "Claude Code"
        "claude"
        "claude.ai"
    )
    for svc in "${services[@]}"; do
        credentials=$(security find-generic-password -s "$svc" -w 2>/dev/null)
        if [[ $? -eq 0 && -n "$credentials" ]]; then
            KEYCHAIN_SERVICE="$svc"
            # Capture the account name from the keychain entry
            KEYCHAIN_ACCOUNT=$(security find-generic-password -s "$svc" 2>/dev/null | grep '"acct"<blob>=' | sed 's/.*"acct"<blob>="\([^"]*\)".*/\1/' | tr -d '[:space:]' | head -1)
            # If no account found, default to current user
            [[ -z "$KEYCHAIN_ACCOUNT" ]] && KEYCHAIN_ACCOUNT="$USER"
            echo "$credentials"
            return 0
        fi
    done
    echo ""
    return 1
}

# 写入凭证到 macOS Keychain
write_keychain_credentials() {
    local credentials="$1"
    # Use the captured account name, or default to current user
    local username="${KEYCHAIN_ACCOUNT:-$USER}"

    # 先删除现有的凭证 (use both account and service to target exact entry)
    security delete-generic-password -a "$username" -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1

    # 添加新凭证
    security add-generic-password -a "$username" -s "$KEYCHAIN_SERVICE" -w "$credentials" >/dev/null 2>&1
    local result=$?

    if [[ $result -eq 0 ]]; then
        echo -e "${BLUE}🔑 Credentials written to Keychain (account: $username)${NC}" >&2
    else
        echo -e "${RED}❌ Failed to write credentials to Keychain (error code: $result)${NC}" >&2
        echo -e "${YELLOW}💡 Try: security unlock-keychain login.keychain-db${NC}" >&2
        echo -e "${YELLOW}💡 Or check: Keychain Access app → login keychain → right-click → Change Settings${NC}" >&2
    fi

    return $result
}

# Clear cached oauthAccount from ~/.claude.json to force fresh user data fetch
#
# Why this is needed:
#   Claude Code caches the user's OAuth account info (email, organization) in ~/.claude.json
#   under the "oauthAccount" key. When switching between accounts, the keychain credentials
#   are updated, but Claude Code continues to display the old cached user info until restart.
#   By clearing this cache, we force Claude Code to fetch fresh user data on next launch.
#
# What triggers cache creation:
#   Claude Code creates this cache when it first authenticates with a Claude Pro account.
#   The cache persists across sessions until explicitly cleared or the file is deleted.
#
# Edge cases handled:
#   - File doesn't exist: Returns success (nothing to clear)
#   - python3 not available: Returns error with warning
#   - File is locked/read-only: Python will raise exception, caught and logged
#   - Malformed JSON: Python will raise exception, caught and logged
#
clear_oauth_account_cache() {
    local claude_json="$HOME/.claude.json"

    if [[ ! -f "$claude_json" ]]; then
        return 0
    fi

    # Check if python3 is available
    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}⚠️  python3 not found, cannot clear oauth cache${NC}" >&2
        return 1
    fi

    # Remove oauthAccount field from the JSON
    # Pass path as argument to avoid shell variable injection into Python code
    local py_output
    py_output=$(python3 - "$claude_json" << 'PYEOF'
import json
import sys

try:
    claude_json = sys.argv[1]
    with open(claude_json, 'r') as f:
        data = json.load(f)

    if 'oauthAccount' in data:
        del data['oauthAccount']
        with open(claude_json, 'w') as f:
            json.dump(data, f, indent=2)
        print('oauthAccount cache cleared', file=sys.stderr)
except Exception as e:
    print(f'Warning: Could not clear oauth cache: {e}', file=sys.stderr)
PYEOF
2>&1)
    local py_exit=$?

    if [[ -n "$py_output" ]]; then
        echo -e "${BLUE}🔄 $py_output${NC}" >&2
    fi

    return $py_exit
}

# 调试函数：验证 Keychain 中的凭证
debug_keychain_credentials() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi

    echo -e "${BLUE}🔍 Debug: Checking Keychain credentials${NC}"

    # Call read_keychain_credentials and capture output without subshell losing KEYCHAIN_ACCOUNT
    local credentials
    credentials=$(read_keychain_credentials)
    # Re-read to set global KEYCHAIN_ACCOUNT (subshell loses it)
    read_keychain_credentials >/dev/null 2>&1
    if [[ -z "$credentials" ]]; then
        echo -e "${RED}❌ No credentials in Keychain${NC}"
        return 1
    fi

    # 提取凭证信息
    local subscription=$(echo "$credentials" | grep -o '"subscriptionType":"[^"]*"' | cut -d'"' -f4)
    local expires=$(echo "$credentials" | grep -o '"expiresAt":[0-9]*' | head -1 | cut -d':' -f2 | tr -d '[:space:]')
    local access_token_preview=$(echo "$credentials" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4 | head -c 20)

    echo -e "${GREEN}✅ Credentials found:${NC}"
    echo "   Service: $KEYCHAIN_SERVICE"
    echo "   Account: ${KEYCHAIN_ACCOUNT:-Unknown}"
    echo "   Subscription: ${subscription:-Unknown}"
    if [[ -n "$expires" ]]; then
        local expires_str=$(date -r $((expires / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
        echo "   Expires: $expires_str"
    fi
    echo "   Token preview: ${access_token_preview}..."

    # Trying to match saved accounts
    if [[ -f "$ACCOUNTS_FILE" ]]; then
        echo -e "${BLUE}🔍 Trying to match saved accounts...${NC}"
        while IFS=': ' read -r name encoded; do
            name=$(echo "$name" | tr -d '"')
            encoded=$(echo "$encoded" | tr -d '"')
            local saved_creds=$(echo "$encoded" | base64 -d 2>/dev/null)
            if [[ "$saved_creds" == "$credentials" ]]; then
                echo -e "${GREEN}✅ Matched account: $name${NC}"
                return 0
            fi
        done < <(grep --color=never -o '"[^"]*": *"[^"]*"' "$ACCOUNTS_FILE")
        echo -e "${YELLOW}⚠️  No matching saved account found${NC}"
    fi
}

# 初始化账号配置文件
init_accounts_file() {
    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo "{}" > "$ACCOUNTS_FILE"
        chmod 600 "$ACCOUNTS_FILE"
    fi
}

# 保存当前账号
save_account() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi
    local account_name="$1"

    if [[ -z "$account_name" ]]; then
        echo -e "${RED}❌ $(t 'account_name_required')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'usage'): ccm save-account <name>${NC}" >&2
        return 1
    fi

    # SECURITY FIX (HIGH-002): Validate account name
    if ! validate_account_name "$account_name"; then
        return 1
    fi

    # 从 Keychain 读取当前凭证
    local credentials
    credentials=$(read_keychain_credentials)
    if [[ -z "$credentials" ]]; then
        echo -e "${RED}❌ $(t 'no_credentials_found')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'please_login_first')${NC}" >&2
        return 1
    fi

    # 初始化账号文件
    init_accounts_file

    # 使用纯 Bash 解析和保存（不依赖 jq）
    # SECURITY FIX (MEDIUM-001): Secure temp file handling
    local temp_file
    temp_file=$(mktemp -t ccm_accounts.XXXXXX) || return 1
    chmod 600 "$temp_file"
    trap 'rm -f "$temp_file" 2>/dev/null' RETURN

    local existing_accounts=""

    if [[ -f "$ACCOUNTS_FILE" ]]; then
        existing_accounts=$(cat "$ACCOUNTS_FILE")
    fi

    # 简单的 JSON 更新：如果是空文件或只有 {}，直接写入
    if [[ "$existing_accounts" == "{}" || -z "$existing_accounts" ]]; then
        local encoded_creds=$(echo "$credentials" | base64)
        cat > "$ACCOUNTS_FILE" << EOF
{
  "$account_name": "$encoded_creds"
}
EOF
    else
        # 读取现有账号，添加新账号
        # 检查账号是否已存在
        # Use escaped name for regex to handle dots and special chars
        local escaped_name
        escaped_name=$(escape_for_regex "$account_name")
        if grep -q "\"$escaped_name\":" "$ACCOUNTS_FILE"; then
            # 更新现有账号
            local encoded_creds=$(echo "$credentials" | base64)
            # 使用 sed 替换现有条目
            sed -i '' "s/\"$escaped_name\": *\"[^\"]*\"/\"$account_name\": \"$encoded_creds\"/" "$ACCOUNTS_FILE"
        else
            # 添加新账号
            local encoded_creds=$(echo "$credentials" | base64)
            # 移除最后的 } (使用 macOS 兼容的命令)
            sed '$d' "$ACCOUNTS_FILE" > "$temp_file"
            # 检查是否需要添加逗号（追加到上一行末尾，不是新行）
            if grep -q '"' "$temp_file"; then
                # Append comma to the last line of existing entries
                sed -i '' '$ s/$/,/' "$temp_file"
            fi
            echo "  \"$account_name\": \"$encoded_creds\"" >> "$temp_file"
            echo "}" >> "$temp_file"
            mv "$temp_file" "$ACCOUNTS_FILE"
        fi
    fi

    chmod 600 "$ACCOUNTS_FILE"

    # 提取订阅类型用于显示
    local subscription_type=$(echo "$credentials" | grep -o '"subscriptionType":"[^"]*"' | cut -d'"' -f4)
    echo -e "${GREEN}✅ $(t 'account_saved'): $account_name${NC}"
    echo -e "   $(t 'subscription_type'): ${subscription_type:-Unknown}"
    # Note: temp_file cleanup handled by trap on RETURN
}

# 切换到指定账号
switch_account() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi
    local account_name="$1"

    if [[ -z "$account_name" ]]; then
        echo -e "${RED}❌ $(t 'account_name_required')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'usage'): ccm switch-account <name>${NC}" >&2
        return 1
    fi

    # SECURITY FIX (HIGH-002): Validate account name
    if ! validate_account_name "$account_name"; then
        return 1
    fi

    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo -e "${RED}❌ $(t 'no_accounts_found')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'save_account_first')${NC}" >&2
        return 1
    fi

    # 从文件中读取账号凭证
    # Use escaped name for regex to handle dots and special chars
    local escaped_name
    escaped_name=$(escape_for_regex "$account_name")
    local encoded_creds=$(grep -o "\"$escaped_name\": *\"[^\"]*\"" "$ACCOUNTS_FILE" | cut -d'"' -f4)

    if [[ -z "$encoded_creds" ]]; then
        echo -e "${RED}❌ $(t 'account_not_found'): $account_name${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'use_list_accounts')${NC}" >&2
        return 1
    fi

    # 解码凭证
    local credentials=$(echo "$encoded_creds" | base64 -d)

    # Read current credentials to get keychain account name
    # If no existing credentials or read fails, default to current user
    if ! read_keychain_credentials >/dev/null 2>&1; then
        KEYCHAIN_ACCOUNT="$USER"
    fi
    if [[ -z "$KEYCHAIN_ACCOUNT" ]]; then
        KEYCHAIN_ACCOUNT="$USER"
    fi

    # 写入 Keychain
    if write_keychain_credentials "$credentials"; then
        # Clear cached oauthAccount in ~/.claude.json to force fresh fetch
        clear_oauth_account_cache
        echo -e "${GREEN}✅ $(t 'account_switched'): $account_name${NC}"
        echo -e "${YELLOW}⚠️  $(t 'please_restart_claude_code')${NC}"
    else
        echo -e "${RED}❌ $(t 'failed_to_switch_account')${NC}" >&2
        return 1
    fi
}

# 列出所有已保存的账号
list_accounts() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi

    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo -e "${YELLOW}$(t 'no_accounts_saved')${NC}"
        echo -e "${YELLOW}💡 $(t 'use_save_account')${NC}"
        return 0
    fi

    echo -e "${BLUE}📋 $(t 'saved_accounts'):${NC}"

    # 读取并解析账号列表
    local current_creds=$(read_keychain_credentials)

    grep --color=never -o '"[^"]*": *"[^"]*"' "$ACCOUNTS_FILE" | while IFS=': ' read -r name encoded; do
        # 清理引号
        name=$(echo "$name" | tr -d '"')
        encoded=$(echo "$encoded" | tr -d '"')

        # 解码并提取信息
        local creds=$(echo "$encoded" | base64 -d 2>/dev/null)
        local subscription=$(echo "$creds" | grep -o '"subscriptionType":"[^"]*"' | cut -d'"' -f4)
        local expires=$(echo "$creds" | grep -o '"expiresAt":[0-9]*' | head -1 | cut -d':' -f2)

        # 检查是否是当前账号
        local is_current=""
        if [[ "$creds" == "$current_creds" ]]; then
            is_current=" ${GREEN}✅ ($(t 'active'))${NC}"
        fi

        # 格式化过期时间
        local expires_str=""
        if [[ -n "$expires" ]]; then
            expires_str=$(date -r $((expires / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
        fi

        echo -e "   - ${YELLOW}$name${NC} (${subscription:-Unknown}${expires_str:+, expires: $expires_str})$is_current"
    done
}

# 删除已保存的账号
delete_account() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi

    local account_name="$1"

    if [[ -z "$account_name" ]]; then
        echo -e "${RED}❌ $(t 'account_name_required')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'usage'): ccm delete-account <name>${NC}" >&2
        return 1
    fi

    # SECURITY FIX (HIGH-002): Validate account name
    if ! validate_account_name "$account_name"; then
        return 1
    fi

    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo -e "${RED}❌ $(t 'no_accounts_found')${NC}" >&2
        return 1
    fi

    # 检查账号是否存在
    # Use escaped name for regex to handle dots and special chars
    local escaped_name
    escaped_name=$(escape_for_regex "$account_name")
    if ! grep -q "\"$escaped_name\":" "$ACCOUNTS_FILE"; then
        echo -e "${RED}❌ $(t 'account_not_found'): $account_name${NC}" >&2
        return 1
    fi

    # 删除账号（使用临时文件）
    # SECURITY FIX (MEDIUM-001): Secure temp file handling
    local temp_file
    temp_file=$(mktemp -t ccm_delete.XXXXXX) || return 1
    chmod 600 "$temp_file"
    trap 'rm -f "$temp_file" 2>/dev/null' RETURN

    grep -v "\"$escaped_name\":" "$ACCOUNTS_FILE" > "$temp_file"

    # 清理可能的逗号问题
    sed -i '' 's/,\s*}/}/g' "$temp_file" 2>/dev/null || sed -i 's/,\s*}/}/g' "$temp_file"
    sed -i '' 's/}\s*,/}/g' "$temp_file" 2>/dev/null || sed -i 's/}\s*,/}/g' "$temp_file"

    mv "$temp_file" "$ACCOUNTS_FILE"
    chmod 600 "$ACCOUNTS_FILE"

    echo -e "${GREEN}✅ $(t 'account_deleted'): $account_name${NC}"
}

# 重命名已保存的账号
rename_account() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi

    local old_name="$1"
    local new_name="$2"

    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo -e "${RED}❌ $(t 'account_name_required')${NC}" >&2
        echo -e "${YELLOW}💡 $(t 'usage'): ccm rename-account <old-name> <new-name>${NC}" >&2
        return 1
    fi

    # SECURITY FIX (HIGH-002): Validate both account names
    if ! validate_account_name "$old_name"; then
        return 1
    fi
    if ! validate_account_name "$new_name"; then
        return 1
    fi

    if [[ "$old_name" == "$new_name" ]]; then
        echo -e "${RED}❌ $(t 'old_and_new_name_same')${NC}" >&2
        return 1
    fi

    if [[ ! -f "$ACCOUNTS_FILE" ]]; then
        echo -e "${RED}❌ $(t 'no_accounts_found')${NC}" >&2
        return 1
    fi

    # Use escaped names for regex to handle dots and special chars
    local escaped_old_name escaped_new_name
    escaped_old_name=$(escape_for_regex "$old_name")
    escaped_new_name=$(escape_for_regex "$new_name")

    # 检查旧账号是否存在
    if ! grep -q "\"$escaped_old_name\":" "$ACCOUNTS_FILE"; then
        echo -e "${RED}❌ $(t 'account_not_found'): $old_name${NC}" >&2
        return 1
    fi

    # 检查新账号名是否已存在
    if grep -q "\"$escaped_new_name\":" "$ACCOUNTS_FILE"; then
        echo -e "${RED}❌ $(t 'account_already_exists'): $new_name${NC}" >&2
        return 1
    fi

    # 重命名账号（使用临时文件）
    # SECURITY FIX (MEDIUM-001): Secure temp file handling
    local temp_file
    temp_file=$(mktemp -t ccm_rename.XXXXXX) || return 1
    chmod 600 "$temp_file"
    trap 'rm -f "$temp_file" 2>/dev/null' RETURN

    # 使用sed替换账号名（处理JSON格式）
    sed "s/\"$escaped_old_name\":/\"$new_name\":/" "$ACCOUNTS_FILE" > "$temp_file"

    mv "$temp_file" "$ACCOUNTS_FILE"
    chmod 600 "$ACCOUNTS_FILE"

    echo -e "${GREEN}✅ $(t 'account_renamed'): $old_name → $new_name${NC}"
}

# 显示当前账号信息
get_current_account() {
    # 检查是否需要禁用颜色（用于 eval）
    if [[ "$NO_COLOR" == "true" ]]; then
        set_no_color
    fi

    local credentials=$(read_keychain_credentials)

    if [[ -z "$credentials" ]]; then
        echo -e "${YELLOW}$(t 'no_current_account')${NC}"
        echo -e "${YELLOW}💡 $(t 'please_login_or_switch')${NC}"
        return 1
    fi

    # 提取信息
    local subscription=$(echo "$credentials" | grep -o '"subscriptionType":"[^"]*"' | cut -d'"' -f4)
    local expires=$(echo "$credentials" | grep -o '"expiresAt":[0-9]*' | cut -d':' -f2 | tr -d ' \n')
    local access_token=$(echo "$credentials" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

    # 格式化过期时间
    local expires_str=""
    if [[ -n "$expires" && "$expires" =~ ^[0-9]+$ ]]; then
        expires_str=$(date -r $((expires / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
    fi

    # 查找账号名称
    local account_name="Unknown"
    if [[ -f "$ACCOUNTS_FILE" ]]; then
        while IFS=': ' read -r name encoded; do
            name=$(echo "$name" | tr -d '"')
            encoded=$(echo "$encoded" | tr -d '"')
            local saved_creds=$(echo "$encoded" | base64 -d 2>/dev/null)
            if [[ "$saved_creds" == "$credentials" ]]; then
                account_name="$name"
                break
            fi
        done < <(grep --color=never -o '"[^"]*": *"[^"]*"' "$ACCOUNTS_FILE")
    fi

    echo -e "${BLUE}📊 $(t 'current_account_info'):${NC}"
    echo "   $(t 'account_name'): ${account_name}"
    echo "   $(t 'subscription_type'): ${subscription:-Unknown}"
    if [[ -n "$expires_str" ]]; then
        echo "   $(t 'token_expires'): ${expires_str}"
    fi
    echo -n "   $(t 'access_token'): "
    mask_token "$access_token"
}

# 显示当前状态（脱敏）
show_status() {
    echo -e "${BLUE}📊 $(t 'current_model_config'):${NC}"
    echo "   BASE_URL: ${ANTHROPIC_BASE_URL:-'Default (Anthropic)'}"
    echo -n "   AUTH_TOKEN: "
    mask_token "${ANTHROPIC_AUTH_TOKEN}"
    echo "   MODEL: ${ANTHROPIC_MODEL:-'$(t "not_set")'}"
    echo "   SMALL_MODEL: ${ANTHROPIC_SMALL_FAST_MODEL:-'$(t "not_set")'}"
    echo ""
    echo -e "${BLUE}🔧 $(t 'env_vars_status'):${NC}"
    echo "   GLM_API_KEY: $(mask_presence GLM_API_KEY)"
    echo "   KIMI_API_KEY: $(mask_presence KIMI_API_KEY)"
    echo "   LONGCAT_API_KEY: $(mask_presence LONGCAT_API_KEY)"
    echo "   MINIMAX_API_KEY: $(mask_presence MINIMAX_API_KEY)"
    echo "   DEEPSEEK_API_KEY: $(mask_presence DEEPSEEK_API_KEY)"
    echo "   ARK_API_KEY: $(mask_presence ARK_API_KEY)"
    echo "   QWEN_API_KEY: $(mask_presence QWEN_API_KEY)"
}

# 清理环境变量
clean_env() {
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_API_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_MODEL
    unset ANTHROPIC_SMALL_FAST_MODEL
    unset API_TIMEOUT_MS
    unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
}

# 切换到Deepseek
switch_to_deepseek() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') Deepseek $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$DEEPSEEK_API_KEY"; then
        # 官方 Deepseek 的 Anthropic 兼容端点
        export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_API_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
        export ANTHROPIC_API_KEY="$DEEPSEEK_API_KEY"
        export ANTHROPIC_MODEL="deepseek-chat"
        export ANTHROPIC_SMALL_FAST_MODEL="deepseek-coder"
        echo -e "${GREEN}✅ $(t 'switched_to') Deepseek（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ Please configure DEEPSEEK_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export DEEPSEEK_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
}

# 切换到Claude Sonnet
switch_to_claude() {
    local account_name="$1"

    echo -e "${YELLOW}🔄 Switching to Claude Sonnet 4.5...${NC}"

    # 如果指定了账号，先切换账号
    if [[ -n "$account_name" ]]; then
        echo -e "${BLUE}📝 Switching to account: $account_name${NC}"
        if ! switch_account "$account_name"; then
            return 1
        fi
    fi

    clean_env
    export ANTHROPIC_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-5-20250929}"
    export ANTHROPIC_SMALL_FAST_MODEL="${CLAUDE_SMALL_FAST_MODEL:-claude-sonnet-4-5-20250929}"
    echo -e "${GREEN}✅ Switched to Claude Sonnet 4.5 (using Claude Pro subscription)${NC}"
    if [[ -n "$account_name" ]]; then
        echo "   $(t 'account'): $account_name"
    fi
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到Claude Opus
switch_to_opus() {
    local account_name="$1"

    echo -e "${YELLOW}🔄 $(t 'switching_to') Claude Opus 4.5...${NC}"

    # 如果指定了账号，先切换账号
    if [[ -n "$account_name" ]]; then
        echo -e "${BLUE}📝 Switching to account: $account_name${NC}"
        if ! switch_account "$account_name"; then
            return 1
        fi
    fi

    clean_env
    export ANTHROPIC_MODEL="${OPUS_MODEL:-claude-opus-4-5-20251101}"
    export ANTHROPIC_SMALL_FAST_MODEL="${OPUS_SMALL_FAST_MODEL:-claude-sonnet-4-5-20250929}"
    echo -e "${GREEN}✅ Switched to Claude Opus 4.5 (using Claude Pro subscription)${NC}"
    if [[ -n "$account_name" ]]; then
        echo "   $(t 'account'): $account_name"
    fi
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到Claude Haiku
switch_to_haiku() {
    local account_name="$1"

    echo -e "${YELLOW}🔄 $(t 'switching_to') Claude Haiku 4.5...${NC}"

    # 如果指定了账号，先切换账号
    if [[ -n "$account_name" ]]; then
        echo -e "${BLUE}📝 Switching to account: $account_name${NC}"
        if ! switch_account "$account_name"; then
            return 1
        fi
    fi

    clean_env
    export ANTHROPIC_MODEL="${HAIKU_MODEL:-claude-haiku-4-5}"
    export ANTHROPIC_SMALL_FAST_MODEL="${HAIKU_SMALL_FAST_MODEL:-claude-haiku-4-5}"
    echo -e "${GREEN}✅ Switched to Claude Haiku 4.5 (using Claude Pro subscription)${NC}"
    if [[ -n "$account_name" ]]; then
        echo "   $(t 'account'): $account_name"
    fi
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到GLM4.6
switch_to_glm() {
    echo -e "${YELLOW}🔄 Switching to GLM4.6 model...${NC}"
    clean_env
    if is_effectively_set "$GLM_API_KEY"; then
        export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
        export ANTHROPIC_API_URL="https://api.z.ai/api/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$GLM_API_KEY"
        export ANTHROPIC_API_KEY="$GLM_API_KEY"
        export ANTHROPIC_MODEL="glm-4.6"
        export ANTHROPIC_SMALL_FAST_MODEL="glm-4.6"
        export API_TIMEOUT_MS="3000000"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.6"
        echo -e "${GREEN}✅ Switched to GLM4.6 (official)${NC}"
    else
        echo -e "${RED}❌ Please configure GLM_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export GLM_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到KIMI for Coding
switch_to_kimi() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') KIMI for Coding $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$KIMI_API_KEY"; then
        # 官方 Kimi 编程专用端点
        export ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
        export ANTHROPIC_API_URL="https://api.kimi.com/coding/"
        export ANTHROPIC_AUTH_TOKEN="$KIMI_API_KEY"
        export ANTHROPIC_API_KEY="$KIMI_API_KEY"
        export ANTHROPIC_MODEL="kimi-for-coding"
        export ANTHROPIC_SMALL_FAST_MODEL="kimi-for-coding"
        echo -e "${GREEN}✅ $(t 'switched_to') KIMI（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ Please configure KIMI_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export KIMI_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到KIMI CN (国内版本)
switch_to_kimi_cn() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') KIMI CN $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$KIMI_API_KEY"; then
        # 国内 Kimi 端点
        export ANTHROPIC_BASE_URL="https://api.moonshot.cn/anthropic"
        export ANTHROPIC_API_URL="https://api.moonshot.cn/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$KIMI_API_KEY"
        export ANTHROPIC_API_KEY="$KIMI_API_KEY"
        export ANTHROPIC_MODEL="kimi-k2-thinking"
        export ANTHROPIC_SMALL_FAST_MODEL="kimi-k2-thinking"
        echo -e "${GREEN}✅ $(t 'switched_to') KIMI CN（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ Please configure KIMI_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export KIMI_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到 MiniMax M2
switch_to_minimax() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') MiniMax M2 $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$MINIMAX_API_KEY"; then
        # 官方 MiniMax 的 Anthropic 兼容端点
        export ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic"
        export ANTHROPIC_API_URL="https://api.minimax.io/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$MINIMAX_API_KEY"
        export ANTHROPIC_API_KEY="$MINIMAX_API_KEY"
        export ANTHROPIC_MODEL="minimax/minimax-m2"
        export ANTHROPIC_SMALL_FAST_MODEL="minimax/minimax-m2"
        echo -e "${GREEN}✅ $(t 'switched_to') MiniMax M2（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ Please configure MINIMAX_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export MINIMAX_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到 Qwen（阿里云官方）
switch_to_qwen() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') Qwen $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$QWEN_API_KEY"; then
        # 阿里云 DashScope 官方 Claude 代理端点
        export ANTHROPIC_BASE_URL="https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy"
        export ANTHROPIC_API_URL="https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy"
        export ANTHROPIC_AUTH_TOKEN="$QWEN_API_KEY"
        export ANTHROPIC_API_KEY="$QWEN_API_KEY"
        # 阿里云 DashScope 支持的模型
        local qwen_model="${QWEN_MODEL:-qwen3-max}"
        local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-instruct}"
        export ANTHROPIC_MODEL="$qwen_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$qwen_small"
        echo -e "${GREEN}✅ $(t 'switched_to') Qwen（$(t 'alibaba_dashscope_official')）${NC}"
    else
        echo -e "${RED}❌ Please configure QWEN_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export QWEN_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到豆包 Seed-Code (Doubao)
switch_to_seed() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') Doubao Seed-Code $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$ARK_API_KEY"; then
        # 官方豆包 Seed-Code
        export ANTHROPIC_BASE_URL="https://ark.cn-beijing.volces.com/api/coding"
        export ANTHROPIC_API_URL="https://ark.cn-beijing.volces.com/api/coding"
        export ANTHROPIC_AUTH_TOKEN="$ARK_API_KEY"
        export ANTHROPIC_API_KEY="$ARK_API_KEY"
        export API_TIMEOUT_MS="3000000"
        export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
        # 豆包 Seed-Code 模型
        local seed_model="${SEED_MODEL:-doubao-seed-code-preview-latest}"
        local seed_small="${SEED_SMALL_FAST_MODEL:-doubao-seed-code-preview-latest}"
        export ANTHROPIC_MODEL="$seed_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$seed_small"
        echo -e "${GREEN}✅ $(t 'switched_to') Seed-Code（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ Please configure ARK_API_KEY${NC}"
        echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}"
        echo -e "${YELLOW}💡 Or:  export ARK_API_KEY=your-key${NC}"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   TIMEOUT: $API_TIMEOUT_MS"
}

# 切换到StreamLake AI (KAT)
switch_to_kat() {
    echo -e "${YELLOW}🔄 $(t 'switching_to') StreamLake AI (KAT) $(t 'model')...${NC}"
    clean_env
    if is_effectively_set "$KAT_API_KEY"; then
        # 获取用户的endpoint ID，默认为配置中的值或环境变量
        local endpoint_id="${KAT_ENDPOINT_ID:-ep-default}"
        # StreamLake AI KAT 端点格式：https://vanchin.streamlake.ai/api/gateway/v1/endpoints/{endpoint_id}/claude-code-proxy
        export ANTHROPIC_BASE_URL="https://vanchin.streamlake.ai/api/gateway/v1/endpoints/${endpoint_id}/claude-code-proxy"
        export ANTHROPIC_API_URL="https://vanchin.streamlake.ai/api/gateway/v1/endpoints/${endpoint_id}/claude-code-proxy"
        export ANTHROPIC_AUTH_TOKEN="$KAT_API_KEY"
        export ANTHROPIC_API_KEY="$KAT_API_KEY"
        # 使用 KAT-Coder 模型
        local kat_model="${KAT_MODEL:-KAT-Coder}"
        local kat_small="${KAT_SMALL_FAST_MODEL:-KAT-Coder}"
        export ANTHROPIC_MODEL="$kat_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$kat_small"
        echo -e "${GREEN}✅ $(t 'switched_to') StreamLake AI (KAT)（$(t 'official')）${NC}"
    else
        echo -e "${RED}❌ $(t 'missing_api_key'): KAT_API_KEY${NC}"
        echo "$(t 'please_set_in_config'): KAT_API_KEY"
        echo ""
        echo "$(t 'example_config'):"
        echo "  export KAT_API_KEY='YOUR_API_KEY'"
        echo "  export KAT_ENDPOINT_ID='ep-xxx-xxx'"
        echo ""
        echo "$(t 'get_endpoint_id_from'): https://www.streamlake.ai/document/DOC/mg6k6nlp8j6qxicx4c9"
        return 1
    fi
    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}🔧 $(t 'switching_info') v2.3.0${NC}"
    echo ""
    echo -e "${YELLOW}$(t 'usage'):${NC} $(basename "$0") [options]"
    echo ""
    echo -e "${YELLOW}$(t 'model_options'):${NC}"
    echo "  deepseek, ds       - env deepseek"
    echo "  kimi, kimi2        - env kimi for coding"
    echo "  kimi-cn            - env kimi cn (China version)"
    echo "  seed, doubao       - env Doubao Seed-Code"
    echo "  kat                - env kat"
    echo "  longcat, lc        - env longcat"
    echo "  minimax, mm        - env minimax"
    echo "  qwen               - env qwen"
    echo "  glm, glm4          - env glm"
    echo "  claude, sonnet, s  - env claude"
    echo "  opus, o            - env opus (Claude Opus 4.5)"
    echo "  haiku, h           - env haiku"
    echo ""
    echo -e "${YELLOW}Claude Pro Account Management:${NC}"
    echo "  save-account <name>        - Save current Claude Pro account"
    echo "  switch-account <name>      - Switch to saved account"
    echo "  list-accounts              - List all saved accounts"
    echo "  delete-account <name>      - Delete saved account"
    echo "  rename-account <old> <new> - Rename saved account"
    echo "  current-account            - Show current account info"
    echo "  claude:account         - Switch account and use Claude (Sonnet)"
    echo "  opus:account           - Switch account and use Opus model"
    echo "  haiku:account          - Switch account and use Haiku model"
    echo ""
    echo -e "${YELLOW}$(t 'tool_options'):${NC}"
    echo "  status, st       - $(t 'show_current_config')"
    echo "  env [model]      - $(t 'output_export_only')"
    echo "  config, cfg      - $(t 'edit_config_file')"
    echo "  help, h          - $(t 'show_help')"
    echo ""
    echo -e "${YELLOW}$(t 'examples'):${NC}"
    echo "  eval \"\$(ccm deepseek)\"                   # Apply in current shell (recommended)"
    echo "  eval \"\$(ccm seed)\"                     # Switch to Doubao Seed-Code with ARK_API_KEY"
    echo "  $(basename "$0") status                      # Check current status (masked)"
    echo "  $(basename "$0") save-account work           # Save current account as 'work'"
    echo "  $(basename "$0") opus:personal               # Switch to 'personal' account with Opus"
    echo ""
    echo -e "${YELLOW}Supported models:${NC}"
    echo "  🌙 KIMI for Coding     - kimi-for-coding (api.kimi.com/coding)"
    echo "  🌕 KIMI CN             - kimi-k2-thinking (api.moonshot.cn/anthropic)"
    echo "  🤖 Deepseek            - deepseek-chat (api.deepseek.com)"
    echo "  🌊 StreamLake (KAT)    - KAT-Coder"
    echo "  🌰 Doubao Seed-Code    - doubao-seed-code-preview-latest (Volcengine Ark)"
    echo "  🐱 LongCat             - LongCat-Flash-Thinking / LongCat-Flash-Chat"
    echo "  🎯 MiniMax M2          - MiniMax-M2 (api.minimax.io)"
    echo "  🐪 Qwen                - qwen3-max (Alibaba DashScope)"
    echo "  🇨🇳 GLM4.6             - glm-4.6 / glm-4.5-air (api.z.ai)"
    echo "  🧠 Claude Sonnet 4.5   - claude-sonnet-4-5-20250929"
    echo "  🚀 Claude Opus 4.5     - claude-opus-4-5-20251101"
    echo "  🔷 Claude Haiku 4.5    - claude-haiku-4-5"
}

# 将缺失的模型ID覆盖项追加到配置文件（仅追加缺失项，不覆盖已存在的配置）
ensure_model_override_defaults() {
    local -a pairs=(
        "DEEPSEEK_MODEL=deepseek-chat"
        "DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat"
        "KIMI_MODEL=kimi-for-coding"
        "KIMI_SMALL_FAST_MODEL=kimi-for-coding"
        "KIMI_CN_MODEL=kimi-k2-thinking"
        "KIMI_CN_SMALL_FAST_MODEL=kimi-k2-thinking"
        "KAT_MODEL=KAT-Coder"
        "KAT_SMALL_FAST_MODEL=KAT-Coder"
        "KAT_ENDPOINT_ID=ep-default"
        "LONGCAT_MODEL=LongCat-Flash-Thinking"
        "LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat"
        "MINIMAX_MODEL=MiniMax-M2"
        "MINIMAX_SMALL_FAST_MODEL=MiniMax-M2"
        "SEED_MODEL=doubao-seed-code-preview-latest"
        "SEED_SMALL_FAST_MODEL=doubao-seed-code-preview-latest"
        "QWEN_MODEL=qwen3-max"
        "QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-instruct"
        "GLM_MODEL=glm-4.6"
        "GLM_SMALL_FAST_MODEL=glm-4.5-air"
        "CLAUDE_MODEL=claude-sonnet-4-5-20250929"
        "CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929"
        "OPUS_MODEL=claude-opus-4-5-20251101"
        "OPUS_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929"
        "HAIKU_MODEL=claude-haiku-4-5"
        "HAIKU_SMALL_FAST_MODEL=claude-haiku-4-5"
    )
    local added_header=0
    for pair in "${pairs[@]}"; do
        local key="${pair%%=*}"
        local default="${pair#*=}"
        if ! grep -Eq "^[[:space:]]*(export[[:space:]]+)?${key}[[:space:]]*=" "$CONFIG_FILE" 2>/dev/null; then
            if [[ $added_header -eq 0 ]]; then
                {
                    echo ""
                    echo "# ---- CCM model ID overrides (auto-added) ----"
                } >> "$CONFIG_FILE"
                added_header=1
            fi
            printf "%s=%s\n" "$key" "$default" >> "$CONFIG_FILE"
        fi
    done
}

# 编辑配置文件
edit_config() {
    # 确保配置文件存在
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}📝 $(t 'config_created'): $CONFIG_FILE${NC}"
        create_default_config
    fi

    # 追加缺失的模型ID覆盖默认值（不触碰已有键）
    ensure_model_override_defaults

    echo -e "${BLUE}🔧 $(t 'opening_config_file')...${NC}"
    echo -e "${YELLOW}$(t 'config_file_path'): $CONFIG_FILE${NC}"
    
    # 按优先级尝试不同的编辑器
    if command -v cursor >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $(t 'using_cursor')${NC}"
        cursor "$CONFIG_FILE" &
        echo -e "${YELLOW}💡 $(t 'config_opened') Cursor $(t 'opened_edit_save')${NC}"
    elif command -v code >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $(t 'using_vscode')${NC}"
        code "$CONFIG_FILE" &
        echo -e "${YELLOW}💡 $(t 'config_opened') VS Code $(t 'opened_edit_save')${NC}"
    elif [[ "$OSTYPE" == "darwin"* ]] && command -v open >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $(t 'using_default_editor')${NC}"
        open "$CONFIG_FILE"
        echo -e "${YELLOW}💡 $(t 'config_opened_default')${NC}"
    elif command -v vim >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $(t 'using_vim')${NC}"
        vim "$CONFIG_FILE"
    elif command -v nano >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $(t 'using_nano')${NC}"
        nano "$CONFIG_FILE"
    else
        echo -e "${RED}❌ $(t 'no_editor_found')${NC}"
        echo -e "${YELLOW}$(t 'edit_manually'): $CONFIG_FILE${NC}"
        echo -e "${YELLOW}$(t 'install_editor'): cursor, code, vim, nano${NC}"
        return 1
    fi
}

# 仅输出 export 语句的环境设置（用于 eval）
emit_env_exports() {
    local target="$1"
    # 加载配置以便进行存在性判断（环境变量优先，不打印密钥）
    load_config || return 1

    # 通用前导：清理旧变量
    local prelude="unset ANTHROPIC_BASE_URL ANTHROPIC_API_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL API_TIMEOUT_MS CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"

    case "$target" in
        "deepseek"|"ds")
            if is_effectively_set "$DEEPSEEK_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.deepseek.com/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.deepseek.com/anthropic'"
                echo "# $(t 'export_if_env_not_set')"
                echo "if [ -z \"\${DEEPSEEK_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${DEEPSEEK_API_KEY}\""
                local ds_model="${DEEPSEEK_MODEL:-deepseek-chat}"
                local ds_small="${DEEPSEEK_SMALL_FAST_MODEL:-deepseek-chat}"
                echo "export ANTHROPIC_MODEL='${ds_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${ds_small}'"
            else
                echo -e "${RED}❌ Please configure DEEPSEEK_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export DEEPSEEK_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "kimi"|"kimi2")
            if is_effectively_set "$KIMI_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.kimi.com/coding/'"
                echo "export ANTHROPIC_API_URL='https://api.kimi.com/coding/'"
                echo "if [ -z \"\${KIMI_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${KIMI_API_KEY}\""
                local kimi_model="${KIMI_MODEL:-kimi-for-coding}"
                local kimi_small="${KIMI_SMALL_FAST_MODEL:-kimi-for-coding}"
                echo "export ANTHROPIC_MODEL='${kimi_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${kimi_small}'"
            else
                echo -e "${RED}❌ Please configure KIMI_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export KIMI_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "kimi-cn")
            if is_effectively_set "$KIMI_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.moonshot.cn/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.moonshot.cn/anthropic'"
                echo "if [ -z \"\${KIMI_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${KIMI_API_KEY}\""
                local kimi_cn_model="${KIMI_CN_MODEL:-kimi-k2-thinking}"
                local kimi_cn_small="${KIMI_CN_SMALL_FAST_MODEL:-kimi-k2-thinking}"
                echo "export ANTHROPIC_MODEL='${kimi_cn_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${kimi_cn_small}'"
            else
                echo -e "${RED}❌ Please configure KIMI_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export KIMI_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "qwen")
            if is_effectively_set "$QWEN_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy'"
                echo "export ANTHROPIC_API_URL='https://dashscope.aliyuncs.com/api/v2/apps/claude-code-proxy'"
                echo "if [ -z \"\${QWEN_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${QWEN_API_KEY}\""
                local qwen_model="${QWEN_MODEL:-qwen3-max}"
                local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-instruct}"
                echo "export ANTHROPIC_MODEL='${qwen_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${qwen_small}'"
            else
                echo -e "${RED}❌ Please configure QWEN_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export QWEN_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "glm"|"glm4"|"glm4.6")
            if is_effectively_set "$GLM_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='3000000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.z.ai/api/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.z.ai/api/anthropic'"
                echo "if [ -z \"\${GLM_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${GLM_API_KEY}\""
                local glm_model="${GLM_MODEL:-glm-4.6}"
                local glm_small="${GLM_SMALL_FAST_MODEL:-glm-4.5-air}"
                echo "export ANTHROPIC_MODEL='${glm_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${glm_small}'"
                echo "export ANTHROPIC_DEFAULT_HAIKU_MODEL='glm-4.5-air'"
                echo "export ANTHROPIC_DEFAULT_SONNET_MODEL='glm-4.6'"
                echo "export ANTHROPIC_DEFAULT_OPUS_MODEL='glm-4.6'"
            else
                echo -e "${RED}❌ Please configure GLM_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export GLM_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "claude"|"sonnet"|"s")
            echo "$prelude"
            # 官方 Anthropic 默认网关，无需设置 BASE_URL
            echo "unset ANTHROPIC_BASE_URL"
            echo "unset ANTHROPIC_API_URL"
            echo "unset ANTHROPIC_API_KEY"
            local claude_model="${CLAUDE_MODEL:-claude-sonnet-4-5-20250929}"
            local claude_small="${CLAUDE_SMALL_FAST_MODEL:-claude-sonnet-4-5-20250929}"
            echo "export ANTHROPIC_MODEL='${claude_model}'"
            echo "export ANTHROPIC_SMALL_FAST_MODEL='${claude_small}'"
            ;;
        "opus"|"o")
            echo "$prelude"
            echo "unset ANTHROPIC_BASE_URL"
            echo "unset ANTHROPIC_API_URL"
            echo "unset ANTHROPIC_API_KEY"
            local opus_model="${OPUS_MODEL:-claude-opus-4-5-20251101}"
            local opus_small="${OPUS_SMALL_FAST_MODEL:-claude-sonnet-4-5-20250929}"
            echo "export ANTHROPIC_MODEL='${opus_model}'"
            echo "export ANTHROPIC_SMALL_FAST_MODEL='${opus_small}'"
            ;;
        "haiku"|"h")
            echo "$prelude"
            echo "unset ANTHROPIC_BASE_URL"
            echo "unset ANTHROPIC_API_URL"
            echo "unset ANTHROPIC_API_KEY"
            local haiku_model="${HAIKU_MODEL:-claude-haiku-4-5}"
            local haiku_small="${HAIKU_SMALL_FAST_MODEL:-claude-haiku-4-5}"
            echo "export ANTHROPIC_MODEL='${haiku_model}'"
            echo "export ANTHROPIC_SMALL_FAST_MODEL='${haiku_small}'"
            ;;
        "longcat")
            if ! is_effectively_set "$LONGCAT_API_KEY"; then
                # 兜底：直接 source 配置文件一次（修复某些行格式导致的加载失败）
                if [ -f "$HOME/.ccm_config" ]; then . "$HOME/.ccm_config" >/dev/null 2>&1; fi
            fi
            if is_effectively_set "$LONGCAT_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.longcat.chat/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.longcat.chat/anthropic'"
                echo "if [ -z \"\${LONGCAT_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${LONGCAT_API_KEY}\""
                local lc_model="${LONGCAT_MODEL:-LongCat-Flash-Thinking}"
                local lc_small="${LONGCAT_SMALL_FAST_MODEL:-LongCat-Flash-Chat}"
                echo "export ANTHROPIC_MODEL='${lc_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${lc_small}'"
            else
                echo "# ❌ $(t 'not_detected') LONGCAT_API_KEY" 1>&2
                return 1
            fi
            ;;
        "minimax"|"mm")
            if is_effectively_set "$MINIMAX_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.minimax.io/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.minimax.io/anthropic'"
                echo "if [ -z \"\${MINIMAX_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${MINIMAX_API_KEY}\""
                local mm_model="${MINIMAX_MODEL:-minimax/minimax-m2}"
                local mm_small="${MINIMAX_SMALL_FAST_MODEL:-minimax/minimax-m2}"
                echo "export ANTHROPIC_MODEL='${mm_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${mm_small}'"
            else
                echo -e "${RED}❌ Please configure MINIMAX_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export MINIMAX_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "seed"|"doubao")
            if is_effectively_set "$ARK_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='3000000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://ark.cn-beijing.volces.com/api/coding'"
                echo "export ANTHROPIC_API_URL='https://ark.cn-beijing.volces.com/api/coding'"
                echo "if [ -z \"\${ARK_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${ARK_API_KEY}\""
                local seed_model="${SEED_MODEL:-doubao-seed-code-preview-latest}"
                local seed_small="${SEED_SMALL_FAST_MODEL:-doubao-seed-code-preview-latest}"
                echo "export ANTHROPIC_MODEL='${seed_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${seed_small}'"
            else
                echo -e "${RED}❌ Please configure ARK_API_KEY${NC}" >&2
                echo -e "${YELLOW}💡 Run: ccm config  # Then add your API key${NC}" >&2
                echo -e "${YELLOW}💡 Or:  export ARK_API_KEY=your-key${NC}" >&2
                return 1
            fi
            ;;
        "kat")
            if ! is_effectively_set "$KAT_API_KEY"; then
                # 兜底：直接 source 配置文件一次
                if [ -f "$HOME/.ccm_config" ]; then . "$HOME/.ccm_config" >/dev/null 2>&1; fi
            fi
            if is_effectively_set "$KAT_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                # 使用用户的 endpoint ID，默认为 ep-default
                local kat_endpoint="${KAT_ENDPOINT_ID:-ep-default}"
                echo "export ANTHROPIC_BASE_URL='https://vanchin.streamlake.ai/api/gateway/v1/endpoints/${kat_endpoint}/claude-code-proxy'"
                echo "export ANTHROPIC_API_URL='https://vanchin.streamlake.ai/api/gateway/v1/endpoints/${kat_endpoint}/claude-code-proxy'"
                echo "if [ -z \"\${KAT_API_KEY}\" ] && [ -f \"\$HOME/.ccm_config\" ]; then . \"\$HOME/.ccm_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${KAT_API_KEY}\""
                local kat_model="${KAT_MODEL:-KAT-Coder}"
                local kat_small="${KAT_SMALL_FAST_MODEL:-KAT-Coder}"
                echo "export ANTHROPIC_MODEL='${kat_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${kat_small}'"
            else
                echo "# ❌ $(t 'missing_api_key'): KAT_API_KEY" 1>&2
                echo "# $(t 'please_set_in_config'): KAT_API_KEY" 1>&2
                echo "# $(t 'get_endpoint_id_from'): https://www.streamlake.ai/document/DOC/mg6k6nlp8j6qxicx4c9" 1>&2
                return 1
            fi
            ;;
        *)
            echo "# $(t 'usage'): $(basename "$0") env [deepseek|kimi|qwen|glm|claude|opus|minimax|kat]" 1>&2
            return 1
            ;;
    esac
}


# 主函数
main() {
    # 加载配置（环境变量优先）
    if ! load_config; then
        return 1
    fi

    # 处理参数
    local cmd="${1:-help}"

    # 检查是否是 model:account 格式
    if [[ "$cmd" =~ ^(claude|sonnet|opus|haiku|s|o|h):(.+)$ ]]; then
        local model_type="${BASH_REMATCH[1]}"
        local account_name="${BASH_REMATCH[2]}"

        # 先切换账号：将输出重定向到stderr，避免污染stdout（stdout仅用于export语句）
        switch_account "$account_name" 1>&2 || return 1

        # 然后仅输出对应模型的 export 语句，供调用方 eval
        case "$model_type" in
            "claude"|"sonnet"|"s")
                emit_env_exports claude
                ;;
            "opus"|"o")
                emit_env_exports opus
                ;;
            "haiku"|"h")
                emit_env_exports haiku
                ;;
        esac
        return $?
    fi

    case "$cmd" in
        # 账号管理命令
        "save-account")
            shift
            save_account "$1"
            ;;
        "switch-account")
            shift
            switch_account "$1"
            ;;
        "list-accounts")
            list_accounts
            ;;
        "delete-account")
            shift
            delete_account "$1"
            ;;
        "rename-account")
            shift
            rename_account "$1" "$2"
            ;;
        "current-account")
            get_current_account
            ;;
        "debug-keychain")
            debug_keychain_credentials
            ;;
        # 模型切换命令
        "deepseek"|"ds")
            emit_env_exports deepseek
            ;;
        "kimi"|"kimi2")
            emit_env_exports kimi
            ;;
        "kimi-cn")
            emit_env_exports kimi-cn
            ;;
        "qwen")
            emit_env_exports qwen
            ;;
        "kat")
            emit_env_exports kat
            ;;
        "longcat"|"lc")
            emit_env_exports longcat
            ;;
        "minimax"|"mm")
            emit_env_exports minimax
            ;;
        "seed"|"doubao")
            emit_env_exports seed
            ;;
        "glm"|"glm4"|"glm4.6")
            emit_env_exports glm
            ;;
        "claude"|"sonnet"|"s")
            emit_env_exports claude
            ;;
        "opus"|"o")
            emit_env_exports opus
            ;;
        "haiku"|"h")
            emit_env_exports haiku
            ;;
        "env")
            shift
            emit_env_exports "${1:-}"
            ;;
        "status"|"st")
            show_status
            ;;
        "config"|"cfg")
            edit_config
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            # SECURITY FIX (LOW-002): Sanitize user input before displaying
            echo -e "${RED}❌ $(t 'unknown_option'): $(sanitize_for_display "$1")${NC}" >&2
            echo "" >&2
            show_help >&2
            return 1
            ;;
    esac
}

# 执行主函数
main "$@"
