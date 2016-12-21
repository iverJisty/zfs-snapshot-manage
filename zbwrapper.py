#!/usr/local/bin/python2
import ConfigParser
import argparse
import string,os,sys,time
import subprocess
import signal
import copy

config_arg = None

def min( time ):
    if time[-1] == 'm':
        return int(time[:-1])
    elif time[-1] == 'h':
        return int(time[:-1]) * 60
    elif time[-1] == 'd':
        return int(time[:-1]) * 24 * 60
    elif time[-1] == 'w':
        return int(time[:-1]) * 24 * 60 * 7

def reloadCfg(signum, frame):
    # Run daemon again
    cmd = [ '/usr/local/bin/zbackupd', '--config', config_arg.config[0] ]
    os.execvp( '/usr/local/bin/zbackupd', cmd )

def writePidfile():
    pid = os.getpid()
    f = open('/var/run/zbackupd.pid','w')
    f.write( str(pid) )
    f.close()

def closeProg(signum, frame):
    os.remove('/var/run/zbackupd.pid')
    sys.exit(0)

def daemonLize( arg ):
    pid = os.fork()
    if pid == 0:
        p = os.fork()
        if p == 0:
            writePidfile()
            si = open('/dev/null', 'r')
            so = open('/dev/null', 'a+')
            se = open('/dev/null', 'a+', 0)
            os.dup2(si.fileno(), sys.stdin.fileno())
            os.dup2(so.fileno(), sys.stdout.fileno())
            os.dup2(se.fileno(), sys.stderr.fileno())

            parseCfg( arg )
        else:
            sys.exit(0)
    else:
        sys.exit(0)

def parseCfg( arg ):

    # Backup arg
    global config_arg
    config_arg = copy.copy( arg )


    # Register SIGHUP
    signal.signal( signal.SIGHUP, reloadCfg )
    # Register SIGHUP
    signal.signal( signal.SIGTERM, closeProg )

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
            routine.append(( '/usr/local/bin/zbackup ' + i + ' ' + rotate, min(period) ))


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
        cmd += '/usr/local/bin/zbackup --list '
        if arg.list == []:
            cmd += ' '.join(arg.list)
    elif arg.delete != None:
        cmd += '/usr/local/bin/zbackup --delete '
        cmd += ' '.join(arg.delete)
    else:
        if arg.dataset != None:
            if arg.count != None:
                cmd += '/usr/local/bin/zbackup ' + arg.dataset + ' ' + arg.count
            else:
                cmd += '/usr/local/bin/zbackup ' + arg.dataset
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
        if s.daemon == True:
            daemonLize(s)
        else:
            parseCfg(s)
    else:
        defaultCmd(s)




