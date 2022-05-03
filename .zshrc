# Exports
export GOPATH=$HOME/go
export PATH=$HOME/.local/bin:$GOPATH/bin:$PATH
export EDITOR=nvim
export GPG_TTY=$(tty)
export SAM_CLI_TELEMETRY=0
export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT='true'

# Aliases
function ec2() { aws ec2 describe-instances --profile es | jq -c '.Reservations | .[] | .Instances | .[] | {InstanceId: .InstanceId, Name: (.Tags[]?|select(.Key=="Name")|.Value)}' | grep -iF "$@" }
alias sso="aws sso login"
alias ssm="aws ssm start-session --profile=es --target $@" 
alias up="brew autoremove && brew update && brew upgrade && brew upgrade --cask --greedy && brew cleanup -s && brew doctor && brew missing"
alias vim=nvim

# Fix home and end on macOS
bindkey '\e[H'    beginning-of-line
bindkey '\e[F'    end-of-line

# Dedupe history
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Enable completion
# https://web.archive.org/web/20220430023658/https://github.com/pypa/pipx/issues/621#issuecomment-1085704307
autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

# Make autocompletion case insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Things to autocomplete
complete -C '$(brew --prefix)/bin/aws_completer' aws
eval "$(register-python-argcomplete pipx)"

# JDK switching
# Usage: $ jdk <version> such as 1.8, 11, 17

jdk() {
        version=$1
        export JAVA_HOME=$(/usr/libexec/java_home -v"$version");
        java -version
 }

# node switching
# Modified from https://web.archive.org/web/20220407192648/https://blog.cyborch.com/making-nvm-and-volta-co-exist-with-zsh/

export NVM_DIR="$HOME/.nvm"

autoload -U add-zsh-hook

clear-volta() {
  export VOLTA_HOME=
  export PATH=`echo $PATH | perl -ane 's|:.*?volta/bin:|:|;s|^.*?volta/bin:||;print'`
}

load-nvmrc() {
  local nvmrc_path=`pwd`/.nvmrc
  
  if [ -e "$nvmrc_path" ] ; then
    if [[ "$__npm_initialized" != "1" ]] ; then
      # explicitly do not try to co-exist with volta
      clear-volta
      
      __npm_initialized=1
      [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh" 
    fi

    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [[ "$nvmrc_node_version" == "N/A" ]]; then
      nvm install >/dev/null
    elif [[ "$nvmrc_node_version" != `nvm version` ]]; then
      nvm use >/dev/null
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

init-volta() {
  if [[ "$VOLTA_HOME" == "" ]] ; then
    export __npm_initialized=0
    export VOLTA_HOME="$HOME/.volta"
    export PATH=`echo $PATH | perl -ane 's|:.*?\.nvm/.*?:|:|;s|^.*?\.nvm/.*?:||;print'`
    export PATH="$VOLTA_HOME/bin:$PATH"
  fi
}

autoload -U add-zsh-hook
load-volta() {
  local package_path=`pwd`/package.json
  
  if [ -e "$package_path" ] ; then
    if [[ `jq -cM '.volta' $package_path` != "null" ]] ; then
      if [[ "$VOLTA_HOME" == "" ]] ; then
        init-volta
      fi
    fi
  fi
}
add-zsh-hook chpwd load-volta
load-volta

# PS1 https://web.archive.org/web/20220120141322/https://salferrarello.com/zsh-git-status-prompt/
# Autoload zsh add-zsh-hook and vcs_info functions (-U autoload w/o substition, -z use zsh style)
autoload -Uz add-zsh-hook vcs_info
# Enable substitution in the prompt.
setopt prompt_subst
# Run vcs_info just before a prompt is displayed (precmd)
add-zsh-hook precmd vcs_info
# add ${vcs_info_msg_0} to the prompt
# e.g. here we add the Git information in red  
PROMPT='%1~ %F{red}${vcs_info_msg_0_}%f %# '

# Enable checking for (un)staged changes, enabling use of %u and %c
zstyle ':vcs_info:*' check-for-changes true
# Set custom strings for an unstaged vcs repo changes (*) and staged changes (+)
zstyle ':vcs_info:*' unstagedstr ' *'
zstyle ':vcs_info:*' stagedstr ' +'
# Set the format of the Git information for vcs_info
zstyle ':vcs_info:git:*' formats       '(%b%u%c)'
zstyle ':vcs_info:git:*' actionformats '(%b|%a%u%c)'

