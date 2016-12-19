#!/usr/bin/env python2
import ConfigParser
import argparse
import string,os,sys,time
import subprocess

def min( time ):
    if time[-1] == 'm':
        return int(time[:-1])
    elif time[-1] == 'h':
        return int(time[:-1]) * 60
    elif time[-1] == 'd':
        return int(time[:-1]) * 24 * 60
    elif time[-1] == 'w':
        return int(time[:-1]) * 24 * 60 * 7

def parseCfg( arg ):

    rotate = ""
    period = ""

    routine = []

    cf = ConfigParser.ConfigParser()
    cf.read(arg.config)

    for i in cf.sections():
        if cf.has_option(i, 'enabled') and cf.get(i, 'enabled') == 'no':
            print i + " no enabled."
        else:
            rotate,period = cf.get(i, 'policy').split('x')
            routine.append(( './zbackup.sh ' + i + ' ' + rotate, min(period) ))

    cur_time = time.time()

    # Execute first time
    for i in routine:
        subprocess.call( i[0].split(' ') )

    # Scan every minute
    while True:
        time.sleep(60)
        for i in routine:
            if int((time.time()-cur_time)/60) % i[1] == 0:
                subprocess.call( i[0].split(' ') )



def defaultCmd( arg ):

    cmd = ""
    if arg.list != None:
        cmd += './zbackup --list '
        cmd += ' '.join(arg.list)
    elif arg.delete != None:
        cmd += './zbackup --delete '
        cmd += ' '.join(arg.delete)
    else:
        if arg.dataset != None:
            if arg.count != None:
                cmd += './zbackup ' + arg.dataset + ' ' + arg.count
            else:
                cmd += './zbackup ' + arg.dataset
        else:
            pass

    # Execute it
    subprocess.call( cmd.split(' ') )

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('dataset', nargs='?')
    parser.add_argument('count', nargs='?')
    parser.add_argument('--config', '-c', nargs=1, default='' )
    parser.add_argument('--daemon', action='store_true')
    parser.add_argument('--list', nargs='*')
    parser.add_argument('--delete', nargs='*')
    s = parser.parse_args()

    print s
    if s.config != '':
        parseCfg(s)
    else:
        defaultCmd(s)




