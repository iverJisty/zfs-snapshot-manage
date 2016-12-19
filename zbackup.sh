#!/bin/sh

snaplist=""

getOlderSnap() {
    snaplist=`zfs list -Hr -t snapshot -o name,zbackup:time $1 | grep -v $1/ | grep -v '-' | sort -k 2 | head -n $2`

}

# Args : dataset, rotation_count
createSnap() {

    countCursnap $dataset
    count=$?
    echo "Get amount of current snapshot : $count "

    time=`date +%s`

    if [ $2 -gt $count ]; then
        echo "Adding new snapshot $dataset@$time"

        # Simply add new snapshot
        zfs snapshot $dataset@$time

        # Add our own attribute
        # zfs set zbackup:mark 1 $dataset@$time
        zfs set zbackup:time=$time $dataset@$time


    else
        # Delete the snapshot older than rotation count $3
        echo "Need to delete" $((count-$2+1)) "snapshot"

        getOlderSnap $dataset $((count-$2+1))
        if test -z "$snaplist"; then
            echo "Cannot find snapshot list"
        else
            # Delete the entry in $snaplist
            IFS=$'\n'
            for i in ${snaplist}
            do
                unset IFS
                local name=`echo $i | cut -d ' ' -f 1`
                echo "Deleting snapshot : $name"
                zfs destroy $name
            done

        fi

        echo "Adding new snapshot : $dataset@$time"

        # Add new snapshot
        zfs snapshot $dataset@$time

        # Add our own attribute
        # zfs set zbackup:mark 1 $dataset@$time
        zfs set zbackup:time=$time $dataset@$time
    fi

}

# Args : dataset
countCursnap() {
    # zfs list -r -t snapshot $1
    count=`zfs list -Hr -t snapshot -o zbackup:time $1 | grep -v $1/ | grep -v '-' | wc -l`
    count=`expr $count`
    return $count
}


if [ "$#" == "0" ]; then
    echo "Usage: ./zbackup [[--list | --delete] target dataset [ID] | target dataset [rotation count]]"
fi

arg=0
if [ "$1" = "--list" ]; then
    # Format : ./zbackup --list [target_dataset [ID]]

    counter=0
    tmp=""
    timestamp=""

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
    getOlderSnap $dataset 100

    printf "ID\tDataset\t\tTime\n"
    IFS=$'\n'
    if test -z $3; then
        # List all snapshot
        for i in ${snaplist}
        do
            unset IFS
            counter=$((counter+1))
            tmp=`echo $i | cut -d ' ' -f 2`
            timestamp=`date -j -f %s $tmp +"%Y-%m-%d %H:%M:%S"`
            printf "$counter\t$dataset\t$timestamp\n"

        done
    else
        # List the target snapshot
        for i in ${snaplist}
        do
            unset IFS
            counter=$((counter+1))
            if [ $counter -eq $3 ]; then
                tmp=`echo $i | cut -d ' ' -f 2`
                timestamp=`date -j -f %s $tmp +"%Y-%m-%d %H:%M:%S"`
                printf "$counter\t$dataset\t$timestamp\n"
                break
            fi

        done
    fi


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
    fi

    echo "====Deleting snapshot===="
    echo "Dataset   : $dataset"
    echo "Target ID : $ID"

    getOlderSnap $dataset 100

    IFS=$'\n'
    if test -z $3; then
        # Delete all snapshot
        for i in ${snaplist}
        do
            unset IFS
            name=`echo $i | cut -d ' ' -f 1`
            echo "Deleting snapshot : $name "
            zfs destroy $name

        done
    else
        # Delete the target snapshot
        for i in ${snaplist}
        do
            unset IFS
            counter=$((counter+1))
            name=`echo $i | cut -d ' ' -f 1`
            if [ $counter -eq $3 ]; then
                zfs destroy $name
                break
            fi

        done
    fi

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



