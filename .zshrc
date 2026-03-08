# =========================================================
# Vanilla Zsh implementation of the "Bureau" Theme
# =========================================================

# Allow variables and command substitution in the prompt
setopt PROMPT_SUBST

# --- Git Integration ---
# Get current Git branch
bureau_git_branch() {
  local ref
  ref=$(git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

# Get current Git status and construct indicators
bureau_git_status() {
  # Use porcelain for fast status parsing
  local _INDEX=$(git status --porcelain -b 2> /dev/null)
  local _STATUS=""
  
  # Staged files
  if echo "$_INDEX" | grep -q '^[AMRD]. '; then
    _STATUS="$_STATUS%B%F{green}●%f%b"
  fi
  # Unstaged files
  if echo "$_INDEX" | grep -q '^.[MTD] '; then
    _STATUS="$_STATUS%B%F{yellow}●%f%b"
  fi
  # Untracked files
  if echo "$_INDEX" | grep -E -q '^\?\? '; then
    _STATUS="$_STATUS%B%F{red}●%f%b"
  fi
  # Unmerged/Conflicts
  if echo "$_INDEX" | grep -q '^UU '; then
    _STATUS="$_STATUS%B%F{red}✖%f%b"
  fi
  # Stashed changes
  if git rev-parse --verify refs/stash >/dev/null 2>&1; then
    _STATUS="$_STATUS(%B%F{blue}✹%f%b)"
  fi
  # Commits Ahead
  if echo "$_INDEX" | grep -q '^## .*ahead'; then
    _STATUS="$_STATUS%F{cyan}▴%f"
  fi
  # Commits Behind
  if echo "$_INDEX" | grep -q '^## .*behind'; then
    _STATUS="$_STATUS%F{magenta}▾%f"
  fi
  
  # Clean working directory
  if [[ -z "$_STATUS" ]]; then
    _STATUS="%B%F{green}✓%f%b"
  fi
  
  echo "$_STATUS"
}

# Assemble the full Git right-prompt
bureau_git_prompt() {
  local _branch=$(bureau_git_branch)
  if [[ -n "$_branch" ]]; then
    local _status=$(bureau_git_status)
    echo "[%B%F{green}±%f%F{white}%b${_branch} ${_status}%f]"
  fi
}

# --- Prompt Rendering ---
# The top line of the prompt is printed via precmd so it can be dynamically right-aligned
bureau_precmd() {
  # Print an empty padding line before the prompt
  print
  
  local _PATH="%B%F{white}%~%f%b"
  local _USERNAME="%B%F{white}%n%f%b"
  
  # Make username red if logged in as root
  if [[ $EUID -eq 0 ]]; then
    _USERNAME="%B%F{red}%n%f%b"
  fi
  
  local _LEFT="${_USERNAME}@%m ${_PATH}"
  local _RIGHT="[%*] "
  
  # Evaluate pure text without color escapes to calculate the exact terminal width
  local left_text="${(%):-%n@%m %~}"
  local right_text="${(%):-[%*] }"
  
  local spaces=$(( COLUMNS - ${#left_text} - ${#right_text} ))
  local space_str=""
  if (( spaces > 0 )); then
    space_str=${(l:spaces:: :)} # Zsh parameter expansion to generate whitespace
  fi
  
  # Print the top line (User/Path aligned left, Time aligned right)
  print -rP "${_LEFT}${space_str}${_RIGHT}"
}

# Hook the precmd function so it runs before every prompt
autoload -U add-zsh-hook
add-zsh-hook precmd bureau_precmd

# Main Input Prompt: "> $" (or "> #" for root)
PROMPT='> %(!.%F{red}#%f.%F{green}$%f) '

# Right Prompt: Dynamic Git info
RPROMPT='$(bureau_git_prompt)'

bindkey -v
bindkey '^?' backward-delete-char
export PATH="/home/arein/.local/bin:$PATH"
export PATH="/home/arein/.cargo/bin:$PATH"
export EDITOR=nvim

[ -f "/home/arein/.ghcup/env" ] && . "/home/arein/.ghcup/env" # ghcup-env