#!/bin/bash

#
# dsgadm. Bash script argument parser.
#
# @Date: 2021-09-26
# @Author: liaobaikai
#
# @UpdateTime: 2021-10-10: bug fix
# @UpdateTime: 2021-10-17: parse args by awk.
# @UpdateTime: 2022-01-08: parse args by awk.
# @UpdateTime: 2022-03-31: add mon modele.
# @UpdateTime: 2022-04-06: bug fix(add argument_bachelors variable).
# @UpdateTime: 2022-10-14: bug fix parameter parser mode.
#
# ------------------------------------------------------------------
export COLUMNS=${COLUMNS:-500}

SCRIPT_HOME=$(
        cd $(dirname "$0")
        pwd
)

SCRIPT_VERSION=1.1.1
SCRIPT_AUTHOR=baikai.liao@qq.com
SCRIPT_NAME=$(basename $0)
separator=","
encode_separator=$(echo $separator | sed 's/,/0x2C/g')

argument_count=$#

# use command on options
# $0 [options] COMMAND
OPTION_COMMAND_MODE=1
OPTION_COMMAND_MODE=${OPTION_COMMAND_MODE:-0}
OPTION_COMMAND_MODE=$(echo "$OPTION_COMMAND_MODE" | grep -iE '(^[y](es)?$)|(^1$)|(^on$)|(^true$)')

if [ -n "$OPTION_COMMAND_MODE" ]; then
        COMMAND="$1"
        shift
        argument_count=$(expr $argument_count - 1)
fi

# -r -f -t -s
argument_bachelors=""

# -n:--name baikai -v:--version 1.0.2 ...
argument_couples=""

# /path
argument_raw_value=""

# ---------- parameter start ------------------------------------
DS_DBPS_HOME_FILE=$SCRIPT_HOME/conf/ds_dbps_home.txt
DT_DBPS_HOME_FILE=$SCRIPT_HOME/conf/dt_dbps_home.txt
#param_all=
#param_skip_column_names=
#param_show_ds=
#param_show_dt=
#param_table_format=
# ---------- parameter end ------------------------------------

AWK=
for cmd in "gawk" "nawk" "awk"; do
        type "$cmd" >/dev/null 2>&1
        [ $? -eq 0 ] && AWK=$cmd && break
done

# placeholder statement
pass() {
        printf ""
}

usage() {

        case $COMMAND in
        mon)
                cat <<EOF

Usage: $SCRIPT_NAME $COMMAND [OPTIONS]

Options:
 -h, --help     Print more information on a comman.
 -v, --version  Print version information and quit.
 -a, --all      Print all information, include extra.
 -b, --display-date-threshold
                Only print before the current time. Option: '-200 seconds' '200 seconds ago'
 -c, --color    Print information with color mode.
 -d, --debug    Print information with debug mode.
 -e, --display-error-threshold
                Only print error exceeds threshold
 -g, --display-healthy-threshold
                Only print healthy status. Option: 0, 1
 -l, --display-license-threshold
                Only print license exceeds threshold
 -i, --display-backlog-threshold
                Only print backlog exceeds threshold
 -j, --display-delay-threshold
                Only print delay exceeds threshold
 -p, --display-filesystem-threshold
                Only print filesystem exceeds threshold
 -s, --source   Print ds information.
 -t, --target   Print dt information.
 -x, --spread   Print information and spread mode, default --spread=off.
 --ds=#file     Set ds dbps home file.
 --dt=#file     Set ds dbps home file.
 --time         Print starting time.
 -C, --hide-columns
                Set hide columns number, range 1..21, default "2,3,5,9,10,18,19,20,21"
 -D, --database Save information into database.
 -E, --vertical Print the output of a query (rows) vertically.
 -F, --format   Information output format, option: sql, table, html, none
 -I, --init     Initialization, if necessary.
 -H #path, --dbps-home=#path
                Print a dbps home information.
 -S, --sql      Print database SQL statement.
 -T, --table    Print information with table style.
 -O, --outfile  Write information to file.
 -P, --show-processor
                Show with process bar.
 -X, --dataxone-mode
                Show serivce_name on dataxone mode, default showing dbps home.
 -R, --review   Review monitoring results.

LICENSE UPL 1.0

Copyright (c) 2021 dsgdata.com and/or its affiliates.

EOF

                ;;
        *)
                cat <<EOF

Usage: $SCRIPT_NAME $COMMAND [OPTIONS]

Options:
 -h, --help   Print more information on a comman
 -v, --version  Print version information and quit


LICENSE UPL 1.0

Copyright (c) 2021-2022 dsgdata.com and/or its affiliates.

EOF
                ;;
        esac

}

# No values arguments
# ------------------------------
readonly local bachelors=$(
        cat <<EOF
-a
--all
-E
--vertical
-L
--loop
-c
-d
-i
-t
-h
-r
-l
-s
--print
-T
--table
--color
-X
--dataxone-mode
-x
--spread
-x
--debug
-S
--sql
--time
-P
--show-process-bar
EOF
)

#readonly local argument_replacements=$(cat << EOF
#-k
#--key
#-m
#--module
#-F
#--format
#
#EOF
#);

readonly local argument_aliases=$(
        cat <<EOF
-k:--key
-M:--module
-v:--value
-V:--version
-f:--file
-a:--all
-b:--display-date-threshold
-e:--display-error-threshold
-p:--display-filesystem-threshold
-g:--display-healthy-threshold
-l:--display-license-threshold
-i:--display-backlog-threshold
-j:--display-delay-threshold
-D:--database
-F:--format
-E:--vertical
-H:--dbps-home
-X:--dataxone-mode
-x:--spread
-d:--debug
-C:--hide-columns
-P:--show-process-bar
EOF
)

match_bachelor() {
        echo "$bachelors" | $AWK -v k="$1" '{
for(i = 1; i <= NF; i++){
if($i == k) print $i
}
}'

}

match_aliases() {
        echo "$argument_aliases" | $AWK -v key="$1" -v k="$2" 'BEGIN{
sk = "^" k ":"
skey = ":" key "$"
}{
for(i = 1; i <= NF; i++){
if(k != "" && $i ~ sk){
print substr($i, index($i, ":") + 1)
} else if (key != "" && $i ~ skey){
print substr($i, 0, index($i, ":") - 1)
}
}
}'

}

set_argument_value() {
        value=$(echo "$3" | sed 's/ /0x20/g' | sed 's/,/0x2C/g')
        argument_couples=$(echo "$argument_couples" | $AWK -v vkey="$1" -v vk="$2" -v vv="$value" -v sep="$separator" 'BEGIN{
mkey = vk ":" vkey;
arg_map[mkey] = vv;
}
END{
# NF: args length
for(i = 1; i <= NF; i++){
idx = index($i, "=");
key = substr($i, 0, idx - 1);
val = substr($i, idx + 1);
if (key == mkey && vv != ""){
arg_map[key] = val == "" ? vv : val "" sep "" vv;
} else {
arg_map[key] = val;
}
}
for(key in arg_map){
printf key "=" arg_map[key] " "
}
}')
}

get_argument_value() {
        echo "$argument_couples" | $AWK -v vkey="$1" -v vk="$2" -v sep="$separator" 'END{
mkey = vk ":" vkey;

# NF: args length
for(i = 1; i <= NF; i++){
idx = index($i, "=");
key = substr($i, 0, idx - 1);
if (key == mkey){
final = substr($i, idx + 1);
len = split(final, arr, sep);
for(j = 1; j <= len; j++) print arr[j];
}
}
}'
}

# bash scripts argument parser.
# ------------------------------
parse_arguments() {
        local opt="$1"
        # local final_opt=""
        # local final_long_opt=""
        local final_opt_val=""

        case $opt in
        --[a-zA-Z]*)
                # long option strings
                # argument start
                # invalid [a-Z] for MACOS

                # 1, --key=abc
                # 2, --key abc

                # 3, --key
                idx=$(echo "$opt" | awk '{print index($0, "=")}')
                if [ $idx -eq 0 ]; then

                        if [ -n "$(match_bachelor "$opt")" ]; then
                                argument_bachelors="$argument_bachelors $opt"
                                return
                        fi

                        # 2, --key abc
                        final_long_opt=$opt
                        final_opt_val=""
                else
                        # 1, --key=abc
                        final_long_opt=$(echo "$opt" | awk -v inx=$idx '{print substr($0, 0, inx - 1)}')
                        final_opt_val=$(echo "$opt" | sed "s/^${final_long_opt}=//")
                fi

                final_opt=$(match_aliases "$final_long_opt")
                set_argument_value "$final_long_opt" "$final_opt" "$final_opt_val"

                if [ -n "$final_opt_val" ]; then
                        final_opt=""
                        final_long_opt=""
                fi

                ;;
        -[a-zA-Z]*)
                # short option strings
                # argument start
                # invalid [a-Z] for MACOS

                # 1, -v 1
                # 2, -v123
                # 3, -p"abcd efg"

                # 4, -rf => -r -f
                final_opt=${opt:0:2}
                final_opt_val=${opt:2}

                final_long_opt=$(match_aliases "" "$final_opt")

                # check argument is bachelor ?
                if [ -n "$(match_bachelor "$final_opt")" ]; then
                        # 4, -rf => -r -f
                        argument_bachelors="$argument_bachelors $final_opt"
                        final_opt=""
                        final_long_opt=""

                        if [ -n "$final_opt_val" ]; then
                                parse_arguments "-${final_opt_val}"
                        fi
                else
                        set_argument_value "$final_long_opt" "$final_opt" "$final_opt_val"
                fi

                if [ -n "$final_opt_val" ]; then
                        final_opt=""
                        final_long_opt=""
                fi

                ;;

        *)
                local val=$opt

                # values
                if [[ -n "$final_opt" ]]; then
                        local final_long_opt2=$(match_aliases "" "$final_opt")
                        #echo "====> $final_long_opt2 $final_opt $val"
                        set_argument_value "$final_long_opt2" "$final_opt" "$val"
                elif [[ -n "$final_long_opt" ]]; then
                        local final_opt2=$(match_aliases "$final_long_opt")
                        #echo "----> $final_long_opt $final_opt2 $val"
                        set_argument_value "$final_long_opt" "$final_opt2" "$val"
                else
                        argument_raw_value="${argument_raw_value}${encode_separator}${val}"
                fi

                [ -n "$final_opt" ] && final_opt=""
                [ -n "$final_long_opt" ] && final_long_opt=""

                ;;
        esac

}

# parse argument options (example)
#
# @param: option
# @param: option value
# @param: command
# ----------------------------
parse_argument_options() {
        option=$1
        option_value=$(echo "$2" | sed 's/\0x20/ /g')
        # option_value=`echo $option_value | sed 's/\0x2C/,/g'`
        command=$3

        case $option in
        ? | -h | --help)
                usage
                exit 0
                ;;
        -V | --version) echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0;;

        # -----------------------------------------
        # options
        # -----------------------------------------
        -a | --all) ARGV_PARAM_ALL=1 ;;
        -b | --display-date-threshold) ARGV_PARAM_DISPLAY_DATE_THRESHOLD=$(echo "$option_value" | tr ',' '\n' | sed 's/\0x2C/,/g') ;;
        -c | --color) ARGV_PARAM_COLOR=1 ;;
        -d | --debug) ARGV_PARAM_DEBUG=1 ;;
        -e | --display-error-threshold) ARGV_PARAM_DISPLAY_ERROR_THRESHOLD=$option_value ;;
        -f | --file)
                ARGV_PARAM_FILE="$option_value" #| tr ',' '\n' | sed 's/\0x2C/,/g"
                ;;
        -g | --display-healthy-threshold) ARGV_PARAM_DISPLAY_HEALTHY_THRESHOLD=$option_value ;;
        -i | --display-backlog-threshold) ARGV_PARAM_DISPLAY_BACKLOG_THRESHOLD=$option_value ;;
        -l | --display-license-threshold) ARGV_PARAM_DISPLAY_LICENSE_THRESHOLD=$option_value ;;
        -j | --display-delay-threshold) ARGV_PARAM_DISPLAY_DELAY_THRESHOLD=$option_value ;;
        -k | --key)
                ARGV_PARAM_KEY="$option_value" #| tr ',' '\n' | sed 's/\0x2C/,/g'
                ;;
        -r) echo "-r" ;;
        -p | --display-filesystem-threshold) ARGV_PARAM_DISPLAY_ERROR_THRESHOLD=$option_value ;;
        -s | --source) ARGV_PARAM_SHOW_DS=1 ;;
        -t | --target) ARGV_PARAM_SHOW_DT=1 ;;
        -x | --spread) ARGV_PARAM_SPREAD_MODE=1 ;;
        -v | --value)
                printf "%s" "--value:"
                echo "$option_value" #| tr ',' '\n' | sed 's/\0x2C/,/g'
                ;;
        -C | --hide-columns) ARGV_PARAM_HIDE_COLUMNS=$(echo "$option_value" | tr ',' '\n' | sed 's/\0x2C/,/g') ;;
        -D | --database) PARGV_ARAM_DATABASE=1 ;;
        -E | --vertical) ARGV_PARAM_VERTICAL=1 ;;
        -F | --format) ARGV_PARAM_FORMAT=$option_value ;;
        -H | --dbps-home) ARGV_PARAM_DBPS_HOME=$option_value ;;
        -I | --init) ARGV_PARAM_INIT=1 ;;
        -L | --loop) ARGV_PARAM_LOOP=1 ;;
        -M | --module) echo "module=>$option_value" ;;
        -N | --skip-column-names) ARGV_PARAM_SKIP_COLUMN_NAMES=1 ;;
        -O | --outfile) ARGV_PARAM_OUT_FILE=$option_value ;;
        -P | --show-process-bar) ARGV_PARAM_PROCESSBAR=1 ;;
        -X | --dataxone-mode) ARGV_PARAM_DATAXONE_MODE=1 ;;
        -S | --sql) ARGV_PARAM_SQL_MODE=1 ;;
        -R | --review) ARGV_PARAM_REVIEW=1 ;;
        -T | --table) ARGV_PARAM_TABLE_FORMAT=1 ;;
        --ds) DS_DBPS_HOME_FILE=$option_value ;;
        --dt) DT_DBPS_HOME_FILE=$option_value ;;
        --time) ARGV_PARAM_TIME_ON=1 ;;

        # -----------------------------------------
        # unknown
        # -----------------------------------------
        --*)
                echo "unknown flag: $option"
                usage
                exit 1
                ;;
        -*)
                echo "unknown shorthand flag: '${option:1:1}' in $option"
                usage
                exit 1
                ;;

        esac
}

check_file() {
        file_name="$1"
        if [ ! -f "$file_name" ]; then
                (echo >&2 "[ERROR] No such file $file_name.")
                return 2
        fi
}

exit_if_abnormal() {
        ret_code=$1
        if [ $ret_code -eq 2 ]; then
                (echo >&2 "Exit abnormally.")
                exit 1
        fi
}

# after parse arguments
#
# @param: command
# ----------------------------
after_parse_arguments() {
        command=$1
        check_file "$DS_DBPS_HOME_FILE"
        exit_if_abnormal $?

        check_file "$DT_DBPS_HOME_FILE"
        exit_if_abnormal $?

        #
        # handle command ...
        case $command in
        -V | --version | version) echo "$SCRIPT_NAME version $SCRIPT_VERSION" ;;
        -h | --help)
                usage
                ;;
        start)
                echo "param_all=$param_all"
                echo "start====>"
                ;;
        stop)
                echo "param_all=$param_all"
                echo "stop====>"
                ;;
        top)
                . $SCRIPT_HOME/dtop.sh
                ;;
        ps)
                echo "ps====>"

                echo "
param_all=$param_all
param_table_format=$param_table_format
param_vertical=$param_vertical
param_show_ds=$param_show_ds
param_show_dt=$param_show_dt
param_sql_mode=$param_sql_mode
param_loop=$param_loop

argument_couples=$argument_couples
argument_bachelors=$argument_bachelors
argument_raw_value=$argument_raw_value
"
                ;;
        reset)
                echo "reset====>"
                ;;
        key)
                . $SCRIPT_HOME/key.sh

                ;;
        mon)

                if [ -n "$ARGV_PARAM_OUT_FILE" ]; then
                        #(>&2 echo "$param_out_file")
                        . $SCRIPT_HOME/mon/mon.sh >>$ARGV_PARAM_OUT_FILE
                else
                        . $SCRIPT_HOME/mon/mon.sh
                fi

                ;;
        reg)
                . $SCRIPT_HOME/reg.sh

                ;;
        review)
                . $SCRIPT_HOME/xcmp-review.sh

                ;;
        *)
                # normal
                usage
                exit 1
                ;;
        esac
}

if [ $argument_count -eq 0 ]; then
        usage
        exit 1
else
        # parse args
        # -------------------------------
        argv=""
        for i in $(seq 1 $argument_count); do
                argv="$1"
                shift
                parse_arguments "$argv"

        done

fi

argument_raw_value=${argument_raw_value:4}
argument_raw_value=$(echo "$argument_raw_value" | sed 's/0x2C/,/g')

#echo "argument_raw_value:$argument_raw_value"
#echo "argument_bachelors:$argument_bachelors"

# argument parser main
# ----------------------------
__sys_argv__() {

        arg_count=$(echo $argument_couples | awk '{print NF}')
        for i in $(seq 1 $arg_count); do
                argument=$(echo $argument_couples | awk -v i=$i '{print $i}')

                keys=$(echo $argument | awk '{print substr($0, 0, index($0, "=") - 1)}')
                value=$(echo $argument | awk '{print substr($0, index($0, "=") + 1)}')

                #keys: -k:--key
                k=$(echo $keys | awk -F ':' '{print $1}')
                key=$(echo $keys | awk -F ':' '{print $2}')
                if [ -n "$key" ]; then
                        parse_argument_options "$key" "$value"
                else
                        parse_argument_options "$k" "$value"
                fi

        done

        for opt in $argument_bachelors; do
                parse_argument_options "$opt" ""
        done

        after_parse_arguments "$COMMAND"
}

__sys_argv__

# dsgadm top
# dsgadm ps
# dsgadm start
# dsgadm stop
# dsgadm reset
# dsgadm mon
# dsgadm mon -s
# dsgadm mon -t
