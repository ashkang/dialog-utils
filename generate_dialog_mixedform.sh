#!/bin/bash

source colors.sh
source jshon.sh
source utils.sh

declare -A def_values;
declare -A config;

dialog_tmp=".dialog.tmp"

function clean_up__gdm
{
    rm -f "${dialog_tmp}" >/dev/null 2>&1

    return 0
}

function generate_dialog_mixedform_rec()
{
    cval=$(get_json_element_from_file "${1} -S -k" "$2") || die "unable to read configuration: $1 from definition schema" "clean_up__gdm"
    for i in $cval; do
        key_ref=`echo "$i" | sed -e 's/^[0-9]*_//'`
        if [ "${key_ref}" == "config" ]; then
            continue;
        fi

        if [ "$3" == "" ]; then
            var_name="${key_ref}"
        else
            var_name="${3}.${key_ref}"
        fi

        cval=$(get_json_element_from_file "${1} -e ${i} -e 0 -t" "$2") || die "corrupted difinition schema: $1.${key_ref}" "clean_up__gdm"
        obj_type="$cval"
        if [ "${obj_type}" == "object" ]; then
            cval=$(get_json_element_from_file "${1} -e ${i} -e 1 -u" "$2") || die "corrupted difinition schema object $1.${key_ref}" "clean_up__gdm"
            title="$cval"
            def_values[$var_name]=""
            ordered_keys+=("$var_name")
            let indent=$indent+2
            dialog_opts+=("$title" "$element" "$indent" " " "$element" "$iy" "$ix" "$flen" "2")
            let element=$element+1
            rc_path="$1 -e ${i} -e 0"
            generate_dialog_mixedform_rec "$rc_path" "$2" "$var_name"
            let indent=$indent-2
        else
            cval=$(get_json_element_from_file "${1} -e ${i} -e 0 -u" "$2") || die "corrupted definition schema entry value: $1.${key_ref}" "clean_up__gdm"
            val="$cval"
            cval=$(get_json_element_from_file "${1} -e ${i} -e 1 -u" "$2") || die "corrupted definition schema entry title: $1.${key_ref}" "clean_up__gdm"
            title="$cval"
            cval=$(get_json_element_from_file "${1} -e ${i} -e 2 -u" "$2") || die "corrupted definition schema entry type: $1.${key_ref}" "clean_up__gdm"
            type="$cval"
            def_values[$var_name]="$val"
            ordered_keys+=("$var_name")
            let indent=$indent+2
            dialog_opts+=("$title" "$element" "$indent" "$val" "$element" "$iy" "$ix" "$flen" "$type")
            # handling retype of hidden elements
            if [ "${type}" == 1 ]; then
                let element=$element+1
                def_values[${var_name}_retyped]="$val"
                ordered_keys+=("${var_name}_retyped");
                dialog_opts+=("Retype $title" "$element" "$indent" "$val" "$element" "$iy" "$ix" "$flen" "$type")
            fi

            let indent=$indent-2
            let element=$element+1
        fi
    done

    return 0
}

function generate_dialog_mixedform()
{
    if [ ! -e "$1" ]; then
        die "specified file $1 not found"
    fi

    test=$(get_json_element_from_file "-k" "$1") || die "parse error reading configuration file" "clean_up__gdm"
    element=$(get_config_from_file "element_begin" "$1" ) || die "unable to read configuration: element_begin from configuration schema" "clean_up__gdm"
    indent=$(get_config_from_file "indent_begin" "$1") || die "unable to read configuration: indent_begin from configuration schema" "clean_up__gdm"
    form_name=$(get_config_from_file "form_name" "$1") || die "unable to read configuration: form_name from configuration schema" "clean_up__gdm"
    height=$(get_config_from_file "height" "$1") || die "unable to read configuration: height from configuration schema" "clean_up__gdm"
    width=$(get_config_from_file "width" "$1") || die "unable to read configuration: width from configuration schema" "clean_up__gdm"
    form_height=$(get_config_from_file "form_height" "$1") || die "unable to read configuration: form_height from configuration schema" "clean_up__gdm"
    iy=$(get_config_from_file "iy" "$1") || die "unable to read configuration: iy from configuration schema" "clean_up__gdm"
    ix=$(get_config_from_file "ix" "$1") || die "unable to read configuration: ix from configuration schema" "clean_up__gdm"
    flen=$(get_config_from_file "flen" "$1") || die "unable to read configuration: flen from configuration schema" "clean_up__gdm"

    dialog_opts=("--clear" "--tab-correct" "--trim" "--insecure" "--mixedform" "$form_name" "$height" "$width" "$form_height")

    generate_dialog_mixedform_rec "" "$1" "" || die "unable to recursively generate options list" "clean_up__gdm"
    dialog "${dialog_opts[@]}" 2> ${dialog_tmp}
    if [ $? -eq 0 ]; then
        dialog_opts_count=`cat ${dialog_tmp} | wc -l` || die "error counting dialog out arguments"
        if [ $dialog_opts_count -ne ${#ordered_keys[@]} ]; then
            die "internal bug: $dialog_opts_count != ${#ordered_keys[@]}. report this incident to ${YELLOW}oi@tidm.ir${RESET}" "clean_up__gdm"
        fi
        for i in ${ordered_keys[@]}; do
            read line;
            config[$i]="$line";
        done < ${dialog_tmp}
        unset ordered_keys
        for i in ${!config[@]}; do
            if [[ "$i" == *_retyped ]]; then
                orig_key=`echo "$i" | sed -e 's/_retyped//g'`
                if [ "${config[$i]}" != "${config[${orig_key}]}" ]; then
                    clear
                    die "${orig_key}s do not match" "clean_up__gdm"
                fi
            fi
        done
        clean_up__gdm
        clear
        return 0
    else
        clear
        clean_up__gdm
        warn "installation terminated"
        exit 1
    fi
}

# generate_dialog_mixedform "$1" || exit 1
# for debugging purposes uncomment the following lines only
# for i in ${!config[@]}; do echo "$i = ${config[$i]}"; done;
# echo "---------"
# or i in ${!def_values[@]}; do echo "$i was ${def_values[$i]}"; done;

# exit 0
