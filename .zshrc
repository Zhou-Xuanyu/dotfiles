# ============================================================
# INSTANT PROMPT (Powerlevel10k)
# Must stay near top. Code requiring console input (password
# prompts, y/n confirmations) goes ABOVE this block.
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# Powerlevel10k theme config — run `p10k configure` to regenerate
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ============================================================
# ZINIT — Plugin Manager
# Auto-installs zinit if not already present
# ============================================================
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Register zinit's own completions with zsh's completion system
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit


# ============================================================
# PLUGINS
# Load order matters:
#   - syntax-highlighting  : must come before autosuggestions
#   - zsh-completions      : adds extra _functions to $fpath
#                            must come before compinit
#   - fzf-tab              : must come before compinit,
#                            and requires `menu no` zstyle
# ============================================================
zinit ice depth=1; zinit light romkatv/powerlevel10k        # theme
zinit light zsh-users/zsh-syntax-highlighting               # real-time syntax colors
zinit light zsh-users/zsh-completions                       # extra completion definitions
zinit light zsh-users/zsh-autosuggestions                   # ghost-text history suggestions
zinit light Aloxaf/fzf-tab                                  # replace completion menu with fzf


# ============================================================
# KEY BINDINGS
# Using vi mode as base. Ctrl+P/N for history navigation
# (more reliable than arrow keys in vi mode)
# ============================================================
bindkey -v                          # vi keybindings as base
bindkey '^P' history-search-backward   # Ctrl+P — older history entry
bindkey '^N' history-search-forward    # Ctrl+N — newer history entry


# ============================================================
# HISTORY
# ============================================================
HISTSIZE=5000                   # lines kept in memory
SAVEHIST=5000                   # lines saved to disk
HISTFILE=~/.zsh_history

setopt appendhistory            # append to HISTFILE, don't overwrite
setopt sharehistory             # share history across all active sessions
setopt hist_ignore_space        # don't save lines that start with a space
setopt hist_ignore_all_dups     # don't save duplicate lines
setopt hist_save_no_dups        # remove older duplicate when saving
setopt hist_find_no_dups        # skip duplicates when searching history


# ============================================================
# COMPLETION
# compinit must run AFTER plugins (so fzf-tab and
# zsh-completions are already registered in $fpath)
# ============================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive matching
zstyle ':completion:*' menu no                           # required for fzf-tab to intercept

autoload -Uz compinit
compinit                        # initialize the completion system


# ============================================================
# FZF — Fuzzy Finder Shell Integration
# Provides: Ctrl+R (history), Ctrl+T (files), **<Tab> (paths)
# Must run after compinit
# ============================================================
eval "$(fzf --zsh)"


# ============================================================
# ALIASES
# ============================================================
alias ls="eza -lh --group-directories-first --icons=auto"   # modern ls with icons
alias grep="grep --color=auto"                               # colorized grep output

# Bare git repo for dotfile management (see: atlassian.com/git/tutorials/dotfiles)
alias config="git --git-dir=$HOME/.cfg --work-tree=$HOME"

# ============================================================
# ENVIRONMENT
# ============================================================
export EDITOR=nvim

# PATH additions — each tool extends PATH with its binaries
# export PATH="$HOME/.local/bin:$PATH"     # (disabled) local user binaries
export PATH="$HOME/scripts:$PATH"          # personal scripts
export PATH="$HOME/.cargo/bin:$PATH"       # Rust/cargo binaries
export PATH="$HOME/.cargo/bin:$PATH"       # (duplicate — safe to remove one)


# ============================================================
# PYENV — Python Version Manager
# Must come after PATH is set up
# ============================================================
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"


# ============================================================
# YAZI — Terminal File Manager
# Wrapper that changes the shell's cwd when yazi exits,
# overrides the system `yazi` binary with a smarter version
# ============================================================
function yazi() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    # use `command` to call the real yazi binary (bypasses this function)
    command yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
