#!/bin/bash

err_msg_no_args="No arguments provided"
err_msg_too_many_args="Too many arguments provided"
err_msg_invalid_args="Invalid argument provided"
err_msg_expected_direction="expecting either 'next' or 'prev'"
err_msg_expected_display="expecting an accurate display index (integer)"

homebrew_bin="/opt/homebrew/bin"
yabai="$homebrew_bin/yabai"
jq="$homebrew_bin/jq"
hs="$homebrew_bin/hs"

display_index_regex='^[0-9]+$'

validate_args() {
    if [ $# -eq 0 ]; then
        >&2 echo "$err_msg_no_args; $err_msg_expected_direction"
        exit 1
    elif [ $# -ge 3 ]; then
        >&2 echo "$err_msg_too_many_args; $err_msg_expected_direction"
        exit 1
    elif [ "$1" != "next" ] && [ "$1" != "prev" ]; then
        >&2 echo "$err_msg_invalid_args; $err_msg_expected_direction"
        exit 1
    elif [ -n "$2" ] && ! [[ $2 =~ $display_index_regex ]]; then
        >&2 echo "$err_msg_invalid_args; $err_msg_expected_display"
        exit 1
    fi

    readonly DIRECTION=$1
    readonly DISPLAY=$2
}


main() {
    spaces=$($yabai -m query --spaces)
    visible_spaces_display_indices=$($jq "[ .[] | select(.\"is-visible\"==true) | .display ]" <<< "$spaces")

    # ensure DISPLAY was set and is valid
    if [ -n "$DISPLAY" ] && $jq -e ".|any(. == $DISPLAY)" <<< "$visible_spaces_display_indices"; then
        # use it (as display index)
        display_index=$DISPLAY

        # get visible space for display
        space=$($jq ".[] | select((.\"is-visible\"==true) and (.display==$display_index))" <<< "$spaces")
    else
        # arg isn't set (or valid if set), default to active display
        display_index=$($jq ".[] | select(.\"has-focus\"==true) | .display" <<< "$spaces")
        
        # default to active space
        space=$($jq ".[] | select(.\"has-focus\"==true)" <<< "$spaces")
    fi

    space_index=$($jq ".index" <<< "$space")
    display_space_indices=$($jq "[.[] | select(.display==$display_index) | .index]" <<< "$spaces")

    if [ "$DIRECTION" == "next" ]; then
        future_space_index=$((space_index + 1))
    else # must be previous
        future_space_index=$((space_index - 1))   
    fi

    if $jq -e ".|any(. == $future_space_index)" <<< "$display_space_indices"; then
        $yabai -m space --focus $future_space_index
    else
        $hs -c "hs.notify.new({title='Yabai', informativeText='Space $future_space_index not found'}):send()"
    fi
}

validate_args "$@"
main