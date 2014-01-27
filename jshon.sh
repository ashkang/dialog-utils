#!/bin/bash

jshon=`which jshon`;

function get_config_from_file()
{
    val=`${jshon} -e config -e $1 -u -F $2 2>/dev/null`
    if [ $? -ne 0 ]; then
        exit 1
    else
        echo ${val}
    fi

    return 0
}

function get_json_element_from_file()
{
    val=`${jshon} $1 -F $2 2>/dev/null`
    if [ $? -ne 0 ]; then
        exit 1
    else
        echo ${val}
    fi

    return 0
}

function has_key()
{
    val=`${jshon} $1 -t -F $2 2>/dev/null`
    if [ $? -eq 0 ]; then
        echo -n "true"
    else
        echo -n "false"
        exit 1
    fi

    return 0
}
