
cat << EOF | mkdef -z
192_155_212_1-255_255_255_248:
    objtype=network
    dhcpserver=10.88.112.26
    gateway=10.90.136.1
    mask=255.255.255.128
    mgtifname=!remote!eth0
    net=10.90.136.0
    tftpserver=10.88.112.26
EOF
