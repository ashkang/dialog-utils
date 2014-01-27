#!/bin/bash

trap "exit 1" TERM
export __me=$$

function die
{
    type -p clean_up

    if [ $? -eq 0 ]; then
        clean_up
    fi

    type -p "$2"

    if [ $? -eq 0 ]; then
        $2
    fi

    echo -e "${RED}error:${RESET} $1"
    kill -s TERM $__me

    return 0
}

function warn
{
    echo -e "${YELLOW}warning:${RESET} $1"

    return 0
}
