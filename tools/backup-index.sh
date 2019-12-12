#!/bin/bash

source ./file-check.sh

path_data=$1
index_uuid=$2
target=$3

current_dir=`pwd`

cd $path_data
path_data=`pwd`
cd $current_dir

cd $target
target=`pwd`
cd $current_dir

little_index_file_suffixes=(dii fdx fnm nvm si dvm tip cfe)

index_tmp_dir=/tmp/es-index-backup/$index_uuid
rm -rf $index_tmp_dir
mkdir -p $index_tmp_dir

index_target_dir=$target/$index_uuid
mkdir -p $index_target_dir

nodes=`ls $path_data/nodes`
for node in $nodes
do
    index_dir=$path_data/nodes/$node/indices/$index_uuid
    if [ ! -d $index_dir ]; then
        continue
    fi

    for sub_dir in `ls $index_dir`
    do
        index_target_shard_dir=$index_target_dir/$sub_dir
        if [ -d $index_target_shard_dir ]; then
            continue
        fi
        mkdir -p $index_target_shard_dir

        if [ "$sub_dir" = "_state" ]; then
            index_state_dir=$index_dir/$sub_dir
            for file in `ls $index_state_dir`
            do
                index_target_state_file=$index_target_shard_dir/$file
                if [ ! -f $index_target_state_file ]; then
                    copy_and_check $index_state_dir/$file $index_target_state_file
                fi
            done

            continue
        fi

        index_target_shard_index_dir=$index_target_shard_dir/index
        mkdir -p $index_target_shard_index_dir

        index_shard_dir=$index_dir/$sub_dir
        index_shard_index_dir=$index_shard_dir/index
        index_tmp_shard_dir=$index_tmp_dir/$sub_dir
        index_tmp_shard_index_dir=$index_tmp_shard_dir/index
        mkdir -p $index_tmp_shard_index_dir
        copy_and_check_dir $index_shard_dir/_state $index_tmp_shard_dir/_state
        copy_and_check_dir $index_shard_dir/translog $index_tmp_shard_dir/translog

        for file in `ls $index_shard_index_dir`
        do
            if [ $file == "write.lock" ]; then
                copy_and_check $index_shard_index_dir/$file $index_tmp_shard_index_dir/$file
                continue
            fi

            if [[ $file == segments_* ]]; then
                copy_and_check $index_shard_index_dir/$file $index_tmp_shard_index_dir/$file
                continue
            fi

            for suffix in ${little_index_file_suffixes[@]} 
            do
                if [[ $file == *.$suffix ]]; then
                    copy_and_check $index_shard_index_dir/$file $index_tmp_shard_index_dir/$file
                    continue 2
                fi
            done

            copy_and_check $index_shard_index_dir/$file $index_target_shard_index_dir/$file
        done

        cd $index_tmp_dir
        tar_file=$sub_dir.tar
        tar cf $tar_file $sub_dir
        copy_and_check $tar_file $index_target_shard_dir/$tar_file
        cd $current_dir
    done
done

chmod -R 755 $index_target_dir
rm -rf $index_tmp_dir
