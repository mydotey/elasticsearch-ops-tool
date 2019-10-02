#!/bin/bash

path_data=$1
index_uuid=$2
target=$3

current_dir=`pwd`

index_tmp_dir=/tmp/es-index-backup/$index_uuid
rm -rf $index_tmp_dir
mkdir -p $index_tmp_dir

index_target_dir=$target/$index_uuid
index_target_state_dir=$index_target_dir/_state
mkdir -p $index_target_state_dir

nodes=`ls $path_data/nodes`
for node in $nodes
do
    index_dir=$path_data/nodes/$node/indices/$index_uuid
    if [ ! -d $index_dir ]; then
        continue
    fi

    for sub_dir in `ls $index_dir`
    do
        if [ "$sub_dir" = "_state" ]; then
            index_state_dir=$index_dir/$sub_dir
            for file in `ls $index_state_dir`
            do
                index_target_state_file=$index_target_state_dir/$file
                if [ ! -f $index_target_state_file ]; then
                    cp $index_state_dir/$file $index_target_state_file
                fi
            done

            continue
        fi

        index_target_shard_dir=$index_target_dir/$sub_dir
        if [ -d $index_target_shard_dir ]; then
            continue
        fi

        index_target_shard_index_dir=$index_target_shard_dir/index
        mkdir -p $index_target_shard_index_dir

        index_shard_dir=$index_dir/$sub_dir
        index_shard_index_dir=$index_shard_dir/index
        for file in `ls $index_shard_index_dir`
        do
            if [ $file != "write.lock" ]; then
                cp $index_shard_index_dir/$file $index_target_shard_index_dir
            fi
        done

        index_tmp_shard_dir=$index_tmp_dir/$sub_dir
        index_tmp_shard_index_dir=$index_tmp_shard_dir/index
        mkdir -p $index_tmp_shard_index_dir
        cp -r $index_shard_dir/_state $index_tmp_shard_dir
        cp -r $index_shard_dir/translog $index_tmp_shard_dir
        cp $index_shard_dir/index/write.lock $index_tmp_shard_index_dir

        cd $index_tmp_dir
        tar_file=$sub_dir.tar
        tar cf $tar_file $sub_dir
        cp $tar_file $index_target_shard_dir
        cd $current_dir
    done
done

rm -rf $index_tmp_dir
