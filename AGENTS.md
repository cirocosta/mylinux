# Agent Notes

## Interactive Commands

When a command needs user interaction, run it in a new tmux window instead of
blocking the agent terminal. Use a clear `codex-*` name and leave the shell open:

```sh
tmux new-window -n codex-task 'cd "$PWD" && interactive-command; exec bash'
```

Tell the user when the new window is waiting for input, then monitor it with
`tmux capture-pane -t codex-task -p`.
