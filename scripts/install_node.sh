#!/bin/bash -x

export ROOT_DIR="$(dirname $(readlink -e $0))"

while [ $# -gt 0 ]; do
  case "$1" in
    "-server_url") SERVER_URL="$2" ; shift ;;

    "-node_id") NODE_ID="$2" ; shift ;;

    "-node_name") NODE_NAME="$2" ; shift ;;

    "-root_passwd") ROOT_PASSWD="$2" ; shift ;;

    "-stemcell") STEMCELL="$2" ; shift ;;

    "-private_ip") PRIVATE_IP="$2" ; shift ;;

    "-private_gateway") PRIVATE_GATEWAY="$2" ; shift ;;

    "-private_netmask") PRIVATE_NETMASK="$2" ; shift ;;

    "-public_ip") PUBLIC_IP="$2" ; shift ;;

    "-public_gateway") PUBLIC_GATEWAY="$2" ; shift ;;

    "-public_netmask") PUBLIC_NETMASK="$2" ; shift ;;

    "-blobstore_dir") BLOBSTORE_DIR="$2" ; shift ;;

    *) echo unknown option $1
       exit 1 ;;
  esac
  shift
done

function wait_ssh() {
  sleep 10
  x=1
  while [ $x -le 750 ]
  do
    set +e
    out="out$RANDOM"
    nc -zv -w 1 $PRIVATE_IP  22 > $out 2>&1
    grep "port \[tcp\/ssh\] succeeded" $out > /dev/null 2>&1
    gre=$?
    rm $out
    set -e
    if [[ $gre -ne 0 ]]; then
      sleep 2
    else
      sleep 2
      break
    fi
    x=$(( $x + 1 ))
  done

  if [ $x == 751 ]; then
    exit 1
  fi
}

send_file="$ROOT_DIR/run.expect $PRIVATE_IP root $ROOT_PASSWD send"
run_cmd="$ROOT_DIR/run.expect $PRIVATE_IP root $ROOT_PASSWD run"
check_ssh="$ROOT_DIR/run.expect $PRIVATE_IP root $ROOT_PASSWD check pwd"

echo "Step 1: reboot bare metal to rescue mode" 
curl -X PUT $SERVER_URL/baremetals/reboot/$NODE_ID/rescue
wait_ssh
echo "  Done!"

echo "Step 2: copy resources to target bare metal"
$check_ssh
count=0
set +e
while true; do
  let count=count+1
  if [ $count -eq 4 ]; then
    echo Giving up
    exit 1
  fi
  wait_ssh
  $send_file $ROOT_DIR/templates/70-persistent-net.rules 
  $send_file $ROOT_DIR/templates/disk_partitions  || continue
  $send_file $ROOT_DIR/templates/interfaces || continue
  $send_file $ROOT_DIR/templates/fstab   || continue
  $send_file $ROOT_DIR/tools/fsarchiver || continue
  $send_file $ROOT_DIR/tools/grub.tgz || continue
  $send_file $ROOT_DIR/bootstrap || continue
#  $send_file $BLOBSTORE_DIR/$STEMCELL  || continue
  break
done
set -e
echo "  Done!"

echo "Step 3: restore the stemcell image in the target bare metal"
$run_cmd "bootstrap -root_passwd $ROOT_PASSWD -stemcell $STEMCELL -server_url $SERVER_URL \
                   -private_ip $PRIVATE_IP -private_gateway $PRIVATE_GATEWAY -private_netmask $PRIVATE_NETMASK \
                   -public_ip $PUBLIC_IP -public_gateway $PUBLIC_GATEWAY -public_netmask $PUBLIC_NETMASK"
echo "  Done!"

echo "Step 4: restart the target bare metal"
#curl -X PUT $SERVER_URL/baremetals/reboot/$NODE_ID/hard
wait_ssh

echo "  Done!"
exit 0
