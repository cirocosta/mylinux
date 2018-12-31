# If not running interactively, don't do anything
[ -z "$PS1" ] && return


# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize


# Improve the history
shopt -s histappend
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=100000
HISTFILESIZE=200000


# Set the prompt
PS1="\[\e[1m\] \w $ \[\e[0m\]"


# Activate bash completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'


# Environment
PATH={{ user_home }}/.local/bin:$PATH
