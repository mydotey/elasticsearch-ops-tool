#!/bin/bash

set -e

copy_retry_times=3

file_sum()
{
    ls -l $1 | awk '{print $5}'
}

copy_and_check()
{
    s_sum=`file_sum $1`
    for i in `seq $copy_retry_times`
    do
        copy_success=`cp $1 $2 | echo $?`
        if [ "$copy_success" = "0" ]; then
            t_sum=`file_sum $2`
            if [ "$s_sum" = "$t_sum" ]; then
                return 0
            fi

            echo "file copy failed: $1, source sum: $s_sum, target sum: $t_sum"
        fi

        echo "file copy failed: $1, ${i}th times"
        rm -f $2
    done

    return 1
}

copy_and_check_dir()
{
    mkdir -p $2
    d=`ls $1`
    for i in $d
    do
        copy_and_check $1/$i $2/$i
    done
}
