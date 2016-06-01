#!/bin/bash -x

export ROOT_DIR="$(dirname $(readlink -e $0))"
source /etc/profile.d/xcat.sh
export HOME=/home/vcap/
xcat_ip=`ifconfig eth0 | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1`

while [ $# -gt 0 ]; do
  case "$1" in
    "-server_url") SERVER_URL="$2" ; shift ;;

    "-node_id") NODE_ID="$2" ; shift ;;

    "-node_name") NODE_NAME="$2" ; shift ;;

    "-root_passwd") ROOT_PASSWD="$2" ; shift ;;

    "-stemcell") STEMCELL="$2" ; shift ;;

    "-private_ip") PRIVATE_IP="$2" ; shift ;;

    "-private_subnet") PRIVATE_SUBNET="$2" ; shift ;;

    "-private_gateway") PRIVATE_GATEWAY="$2" ; shift ;;

    "-private_netmask") PRIVATE_NETMASK="$2" ; shift ;;

    "-public_ip") PUBLIC_IP="$2" ; shift ;;

    "-public_subnet") PUBLIC_SUBNET="$2" ; shift ;;

    "-public_gateway") PUBLIC_GATEWAY="$2" ; shift ;;

    "-public_netmask") PUBLIC_NETMASK="$2" ; shift ;;

    "-blobstore_dir") BLOBSTORE_DIR="$2" ; shift ;;

    "-netboot_image") NETBOOT_IMAGE="$2" ; shift ;;

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

SSH_OPT="-o StrictHostKeyChecking=no"
scp_cmd="scp ${SSH_OPT}"
ssh_cmd="ssh ${SSH_OPT}"

echo "Step 0: check subnet"
subnet_id="$PRIVATE_SUBNET-$PRIVATE_NETMASK"
subnet_name=${subnet_id//./_}
if ! lsdef -t network $subnet_name ; then
  cat << EOF | mkdef -z
$subnet_name:
    objtype=network
    dhcpserver=$xcat_ip
    gateway=$PRIVATE_GATEWAY
    mask=$PRIVATE_NETMASK
    mgtifname=!remote!
    net=$PRIVATE_SUBNET
    tftpserver=$xcat_ip
EOF
  makedhcp -n
fi

dhcp_conf=/etc/dhcp/dhcpd.conf
subnet=$PRIVATE_SUBNET
if grep -B 1 "subnet $subnet" $dhcp_conf | grep -v '!remote!' ; then
  lines=`sed -n "/subnet $subnet/,/# $subnet/p" $dhcp_conf`
  lines=${lines//$'\n'/\\\n}
  sed -i "/subnet $subnet/,/# $subnet/d" $dhcp_conf
  sed -i "s|shared-network eth0 {|shared-network eth0 {\n$lines|" $dhcp_conf
  service isc-dhcp-server restart
fi

getslnodes $NODE_NAME

echo "Step 1: netboot the target bare metal with centos"
rmdef -t node -o $NODE_NAME || echo "no this node"
getslnodes $NODE_NAME > /tmp/node.info
cat /tmp/node.info | mkdef -z -f || echo "existed"
makehosts $NODE_NAME
makedhcp $NODE_NAME
makedns $NODE_NAME
nodeset $NODE_NAME osimage=$NETBOOT_IMAGE
rinstall $NODE_NAME
echo "  Done!"

echo "Step 1.1: waiting for the sshd vailable in the target bare metal"
wait_ssh
echo "  Done!"

echo "Step 2: copy resources to target bare metal"
$ROOT_DIR/run.expect $PRIVATE_IP root $ROOT_PASSWD check pwd
count=0
set +e
while true; do
  let count=count+1
  if [ $count -eq 4 ]; then
    echo Giving up
    exit 1
  fi
  wait_ssh
  $scp_cmd $ROOT_DIR/templates/disk_partitions root@$NODE_NAME:~/ || continue
  $scp_cmd $ROOT_DIR/templates/fstab root@$NODE_NAME:~/ || continue
  $scp_cmd $ROOT_DIR/tools/fsarchiver root@$NODE_NAME:~/ || continue
  $scp_cmd $ROOT_DIR/tools/grub.tgz root@$NODE_NAME:~/ || continue
  $scp_cmd $ROOT_DIR/bootstrap root@$NODE_NAME:~/ || continue
  for file in $BLOBSTORE_DIR/$STEMCELL/* ; do
    $scp_cmd $file root@$NODE_NAME:~/ || continue
  done

  break
done
set -e
echo "  Done!"

echo "Step 3: restore the stemcell image in the target bare metal"
$ssh_cmd -t $NODE_NAME "~/bootstrap -root_passwd $ROOT_PASSWD -stemcell $STEMCELL -server_url $SERVER_URL \
                   -private_ip $PRIVATE_IP -private_gateway $PRIVATE_GATEWAY -private_netmask $PRIVATE_NETMASK \
                   -public_ip $PUBLIC_IP -public_gateway $PUBLIC_GATEWAY -public_netmask $PUBLIC_NETMASK"
echo "  Done!"

echo "Step 4: restart the target bare metal"
nodeset $NODE_NAME boot
# Below is a workaround for this issue: http://sourceforge.net/p/xcat/bugs/3405/
sed -i "s/exit/sanboot --no-describe --drive 0x80/g" /tftpboot/xcat/xnba/nodes/$NODE_NAME 
wait_ssh
echo "  Done!"
exit 0
