ZFS Snapshot Manage
=====

## Usage

./zbackup [--list | --delete] target dataset [ID] | target dataset [rotation count]


## Example
```
$ sudo ./zbackup data/to/backup 5
$ sudo ./zbackup data/to/backup 5
$ sudo ./zbackup --list data/to/backup
====List snapshot====
Dataset   : data/to/backup
Target ID :
ID      Dataset         Time
1       data/to/backup      2016-11-12 14:04:34
2       data/to/backup      2016-11-12 14:11:16
3       data/to/backup      2016-11-12 14:51:45
```
