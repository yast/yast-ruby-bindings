#!/bin/bash
# tmux-uitest.sh - a shell library to test Text User Interface using tmux

SESSION=uitest
: "${VERBOSE=false}"

# $1 shell command for sh -c
tmux_new_session() {
    if $VERBOSE; then
        echo Starting session
    fi
    # -s session name
    # -x width -y height,
    # -d detached
    # FIXME: sleep to be able to see errors when running $1
    tmux new-session -s "$SESSION" -x 80 -y 24 -d sh -c "$1; sleep 9999"
}

# A --quiet grep
# $1 regex (POSIX ERE) to find in captured pane
# retcode: true or false
tmux_grep() {
    local REGEX="$1"
    tmux capture-pane -t "$SESSION" -p | grep -E --quiet "$REGEX"
    RESULT=("${PIPESTATUS[@]}")

    if [ "${RESULT[0]}" != 0 ]; then
        # capturing the pane failed; the session may have exited already
        return 2
    fi
    
    # capturing went fine, pass on the grep result
    test "${RESULT[1]}" = 0
}

# $1 regex (POSIX ERE) to find in captured pane
tmux_await() {
    local REGEX="$1"

    local SLEEPS=(0.1 0.2 0.2 0.5 1 2 2 5)
    for SL in "${SLEEPS[@]}"; do
        tmux_grep "$REGEX" && return 0
        if [ $? = 2 ]; then return 2; fi # session not found
        # text not found, continue waiting for it
        sleep "$SL"
    done
    # text not found, timed out
    false
}

# capture the session to stdout
tmux_capture_pane() {
    tmux capture-pane -t "$SESSION" -p
}

# $1
# $1.txt plain text
# $1.esc text with escape sequences for colors
tmux_capture_pane_to() {
    local OUT="$1"

    # -t target-pane, -p to stdout,
    # -e escape sequences for text and background attributes
    tmux capture-pane -t "$SESSION" -p -e > "$OUT.esc"
    tmux capture-pane -t "$SESSION" -p    > "$OUT.txt"
    # this is racy. if it is a problem we should make .txt from .esc
    # by filtering out the escape sequences
}

# $1 keys ("C-X" for Ctrl-X, "M-X" for Alt-X, think "Meta"); for details see:
#   man tmux | less +/"^KEY BINDINGS"
tmux_send_keys() {
    if $VERBOSE; then
        echo Sending "$1"
    fi
    # -t target-pane
    tmux send-keys -t "$SESSION" "$1"
}

# usage: trap tmux_cleanup EXIT
tmux_cleanup() {
    if tmux_has_session; then
        echo "SCREEN BEGIN (non-empty lines only)"
        tmux_capture_pane | grep .
        echo "SCREEN END"
        tmux_kill_session
    fi
}

# ret code: true or false
tmux_has_session() {
    if $VERBOSE; then
        echo Detecting the session
    fi
    # -t target-session
    tmux has-session -t "$SESSION"
}


tmux_kill_session() {
    if $VERBOSE; then
        echo Killing the session
    fi
    # -t target-session
    tmux kill-session -t "$SESSION"
}
