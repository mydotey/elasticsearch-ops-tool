#!/bin/bash

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

for sub_dir in `ls $index_source_dir`
do
    if [ "$sub_dir" = "_state" ]; then
        cp -r $index_source_dir/$sub_dir $index_tmp_dir
        continue
    fi

    index_source_shard_dir=$index_source_dir/$sub_dir

    tar_file=$sub_dir.tar
    cp $index_source_shard_dir/$tar_file $index_tmp_dir
    cd $index_tmp_dir
    tar xf $tar_file
    rm $tar_file

    index_tmp_shard_index_dir=$index_tmp_dir/$sub_dir/index
    cd $index_tmp_shard_index_dir

    index_source_shard_index_dir=$index_source_shard_dir/index
    for file in `ls $index_source_shard_index_dir`
    do
        ln -s $index_source_shard_index_dir/$file $file
    done

    cd $current_dir
done

indices_path=$path_data/nodes/0/indices
mkdir -p $indices_path
mv $index_tmp_dir $indices_path
