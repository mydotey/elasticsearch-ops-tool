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
        copy_result=`cp -f $1 $2 || echo bad-copy`
        if [ "$copy_result" != "bad-copy" ]; then
            t_sum=`file_sum $2`
            if [ "$s_sum" = "$t_sum" ]; then
                return 0
            fi

            echo "file copy failed: $1, source sum: $s_sum, target sum: $t_sum"
        fi

        echo "file copy failed: $1, ${i}th times"
        rm -f $2 || echo "ignore error: rm -f $2"
        sleep 10
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

check_retry_times=60
ensure_file_exists()
{
    for i in `seq $check_retry_times`
    do
        if [ -f $1 ] || [ -d $1 ]; then
            return 0
        fi

        sleep 10
    done

    echo "file $1 not exist"
    return 1
}

ensure_file_exists2()
{
    for i in `seq $check_retry_times`
    do
        ls_result=`ls $1 | grep $2 || echo bad-ls`
        if [ "$ls_result" != "bad-ls" ]; then
            return 0
        fi

        sleep 10
    done

    echo "$file $2 not exist in $1"
    return 1
}