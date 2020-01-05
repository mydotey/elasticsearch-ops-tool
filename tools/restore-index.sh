#!/bin/bash

set -e

source ./file-copy.sh

path_data=$1
index_uuid=$2
source=$3

current_dir=`pwd`

cd $path_data
path_data=`pwd`
cd $current_dir

cd $source
source=`pwd`
cd $current_dir

index_tmp_dir=/tmp/es-index-restore/$index_uuid
rm -rf $index_tmp_dir
mkdir -p $index_tmp_dir

index_source_dir=$source/$index_uuid

d=`ls $index_source_dir`
for sub_dir in $d
do
    if [ "$sub_dir" = "_state" ]; then
        copy_and_check_dir $index_source_dir/$sub_dir $index_tmp_dir/$sub_dir
        continue
    fi

    index_source_shard_dir=$index_source_dir/$sub_dir

    tar_file=$sub_dir.tar
    copy_and_check $index_source_shard_dir/$tar_file $index_tmp_dir/$tar_file
    cd $index_tmp_dir
    tar xf $tar_file
    rm $tar_file

    index_tmp_shard_index_dir=$index_tmp_dir/$sub_dir/index
    cd $index_tmp_shard_index_dir

    index_source_shard_index_dir=$index_source_shard_dir/index
    d2=`ls $index_source_shard_index_dir`
    for file in $d2
    do
        ln -s $index_source_shard_index_dir/$file $file
    done

    cd $current_dir
done

indices_path=$path_data/nodes/0/indices
mkdir -p $indices_path
mv $index_tmp_dir $indices_path
