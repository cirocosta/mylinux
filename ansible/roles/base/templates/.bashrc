# if not running interactively, don't do anything
#
[ -z "$PS1" ] && return


# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#
shopt -s checkwinsize


# improve the history
#
shopt -s histappend
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=100000
HISTFILESIZE=200000


# set the prompt layout
#
PS1='\[\e[1m\] \w \$ \[\e[0m\]'


# activate bash completion
#
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


# aliases
#
alias ls='ls --color=auto'
alias grep='grep --color=auto'


# autojump (that `j` thing)
#
eval "$(jump shell)"
