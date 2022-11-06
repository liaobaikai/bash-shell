table_data=${table_data:-""}
table_column_names=""
table_data_separator=";"
table_separator="|"
table_border_separator="+"
table_style=1
table_vertical=0
table_row_count=0


is_hide_column(){
        echo "$table_hide_columns" | tr ',' '\n' | grep -v ^$ | egrep "^$idx$"
}

get_column_max_length(){
        echo "$table_column_names" | awk -F "$table_data_separator" 'BEGIN{max=0}{for(i=1;i<=NF;i++){l=length($i);if(max<l) max=l}}END{print max}'
}

set_table_column_names(){
        local argv=""
        local s=""
        for idx in $(seq 1 $#)
        do
                argv="$1"
                shift
                if test "$(is_hide_column)" == "$idx"  ; then
                        continue
                fi

                s="$s$argv$table_data_separator"
        done
        table_column_names="$s"
}

build_table_row() {
        # showing table with vertical...
        if test $table_vertical -eq 1 ; then
                if test -z "$table_column_names" ; then
                        set_table_column_names $@
                        return
                fi

                table_row_count=`expr $table_row_count + 1`

                #####################################
                # show with vertical mode..
                max=$(get_column_max_length)

                # build split line *********
                local s="$(printf "%${max}s" | tr ' ' '*');$table_row_count. row  $(printf "%${max}s" | tr ' ' '*')\n"

                local argv=""
                local num=0
                for idx in $(seq 1 $#)
                do
                        argv="$1"
                        shift
                        if test "$(is_hide_column)" == "$idx"; then
                                continue
                        fi
                        
                        num=$(expr $num + 1)
                        
                        column_name=$(echo "$table_column_names" | awk -F "$table_data_separator" -v num=$num -v max=$max '{printf("%"max"s", $num)}')

                        s="$s$column_name: $table_data_separator$argv\n"
                done

                table_data="$table_data$s\n"
                return
        fi

        ############# table mode #################
        test $table_style -eq 0  && sep="" || sep="$table_separator"

        table_data="${table_data}${sep}"

        local argv=""
        local s=""
        for idx in $(seq 1 $#)
        do
                argv="$1"
                shift
                if test "$(is_hide_column)" == "$idx"  ; then
                        continue
                fi
                s="$s $argv$table_data_separator$sep"
        done
        
        table_data="$table_data$s\n"
}

build_table_border() {
        # showing table with vertical...
        if test $table_vertical -eq 1 ; then
                return
        fi

        local hide_col_count=$(echo "$table_hide_columns" | tr ',' '\n' | grep -v ^$ | wc -l)

        # showing with table style
        test $table_style -eq 0  && sep="" || sep="$table_border_separator"
        local show_column_count=$(expr $1 - $hide_col_count)

        local border=$(echo $show_column_count | awk -v s1="$table_data_separator" -v s2="$sep" '{s=s2; for(i=1;i<=$1;i++)s=s ""s1""s2}END{print s}')

        test $table_style -eq 1  && table_data="$table_data$border\n"
}

build_table() {
        # showing table with vertical...
        local os=' '
        if test $table_vertical -eq 1 ; then
                table_style=0
                os=''
        fi

        if test $table_style -eq 1 ; then
                echo -e "$table_data" | column -o ' ' -t -s "$table_data_separator" | awk '{if($0 ~ /^+/){gsub(" ","-",$0);print $0}else{print $0}}'
        else
                echo -e "$table_data" | column -o "$os" -t -s "$table_data_separator"
        fi

        table_data=""
        table_column_names=""
        table_hide_columns=""
}
