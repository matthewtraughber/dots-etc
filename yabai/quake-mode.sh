#!/bin/bash

err_msg_no_args="No arguments provided"
err_msg_too_many_args="Too many arguments provided"
err_msg_expected_args="expecting either 'next' or 'prev'"

homebrew_bin="/opt/homebrew/bin"
yabai="$homebrew_bin/yabai"
jq="$homebrew_bin/jq"
hs="$homebrew_bin/hs"

validate_args() {
    if [ $# -eq 0 ]; then
        >&2 echo "$err_msg_no_args; $err_msg_expected_args"
        exit 1
    elif [ $# -ge 2 ]; then
        >&2 echo "$err_msg_too_many_args; $err_msg_expected_args"
        exit 1
    fi

    readonly APP=$1
}

main() {
    windows="$($yabai -m query --windows)"

    app_window=$($jq ".[] | select(.app==\"$APP\")" <<< "$windows")

    id=$($jq '."id"' <<< "$app_window")
    is_visible=$($jq '."is-visible"' <<< "$app_window")
    
    if $is_visible; then
        $hs -c "hs.application.find('$APP'):hide()"
    else
        $yabai -m window "$id" --space mouse && $yabai -m window --focus "$id"

        $hs -c "hs.application.find('$APP'):activate()"
    fi
}

validate_args $@
main