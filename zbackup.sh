#!/bin/sh

snaplist=""

getOlderSnap() {
    snaplist=`zfs list -Hr -t snapshot -o name,zbackup:time $1 | grep -v $1/ | sort -k 2 | head -n $2`

}

# Args : dataset, rotation_count
createSnap() {

    countCursnap $dataset
    count=$?
    echo "Get amount of current snapshot : $count "

    time=`date +%s`

    if [ $2 -gt $count ]; then
        # Simply add new snapshot
        zfs snapshot $dataset@$time

        # Add our own attribute
        # zfs set zbackup:mark 1 $dataset@$time
        zfs set zbackup:time $time $dataset@$time

    else
        # Delete the snapshot older than rotation count $3
        echo "Need to delete" $(($2-count)) "snapshot"
        getOlderSnap $dataset $(($2-count))
        if test -z $snaplist; then
            echo "Cannot find snapshot list"
        else
            echo $snaplist
        fi
    fi

}

# Args : dataset
countCursnap() {
    # zfs list -r -t snapshot $1
    conut=`zfs list -Hr -t snapshot -o zbackup:name $1 | grep -v $1/ | grep -v '-' | wc -l`

    return $count
}

arg=0
if [ "$1" = "--list" ]; then
    # Format : ./zbackup --list [target_dataset [ID]]

    # Get dataset name
    if test -z $2; then
        exit
    else
        dataset=$2
    fi
    if ! test -z $3; then
        ID=$3
    fi

    echo "====List snapshot===="
    echo "Dataset   : $dataset"
    echo "Target ID : $ID"


elif [ "$1" = "--delete" ]; then
    # Format : ./zbackup --delete [target_dataset [ID]]

    # Get dataset name
    if test -z $2; then
        exit
    else
        dataset=$2
    fi

    # Get optional sequence id
    if ! test -z $3; then
        ID=$3
    else
        ID=""
    fi

    echo "====Deleting snapshot===="
    echo "Dataset   : $dataset"
    echo "Target ID : $ID"
else
    # Format : ./zbackup target_dataset [rotation count]

    # Get dataset name
    if test -z $1; then
        exit
    else
        dataset=$1
    fi

    # Get rotate count
    if ! test -z $2; then
        rotate=$2
    else
        rotate=20
    fi

    # cur_time=`date +"%Y-%m-%d %H:%M:%S"`
    echo "====Creating snapshot===="
    echo "Dataset : $dataset"
    echo "Rotation: $rotate"
    createSnap $dataset $rotate


fi



