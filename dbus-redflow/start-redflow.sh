#!/bin/bash
#
# Start script for dbus-redflow
#   First parameter: tty device to use
#
# Keep this script running with daemon tools. If it exits because the
# connection crashes, or whatever, daemon tools will start a new one.
#

tty_dev=$1
app=/opt/color-control/dbus-redflow/dbus-redflow
args="$*"

log()
{
  test -z "$myname" && myname=`basename $0`
  test -t 1 && echo "`date +%Z-%Y.%m.%d-%H:%M:%S` $*"
  # test -z "$logfile" || echo "`date +%Y.%m.%d-%H:%M:%S` [$$] $*" >> $logfile
}

cleanup()
{
  #remove lock
  tty=${tty_dev#/*/} # get part after forward slash
  rm -rf "/var/lock/$tty.lock"
}

terminated()
{
  log "Terminate script with PID $em_pid on device $tty"
  [ -n "$em_pid" ] && kill -s 0 $em_pid 2> /dev/null && kill $em_pid
  cleanup
  exit 0
}

start()
{
  log "start: $app $*"

  # only poll USB rs485 devices!
  MODEL=`udevadm info --query=property -n $tty_dev | grep ID_MODEL=`

  if [ "$MODEL" = "ID_MODEL=USB-Serial_Controller_D" ]; then
    args="$args --zigbee"
  fi
  if [ "$MODEL" = "ID_MODEL=USB-RS485_Cable" ] || [ "$MODEL" = "ID_MODEL=USB-Serial_Controller_D" ]; then
    $app $args &
    em_pid=$!
    #log "dbus-redflow process has PID $em_pid"
    wait $em_pid
    em_pid=
  fi
}

trap "terminated" SIGINT SIGTERM

start

cleanup
