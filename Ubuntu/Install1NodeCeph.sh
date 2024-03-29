#!/usr/bin/bash
sudo apt -y update
sudo apt -y install pciutils virt-what git lvm2 virt-what pciutils python3-pip python3-virtualenv || exit
git clone https://github.com/ceph/ceph-deploy
cdir=$(pwd)
cd ceph-deploy
./bootstrap 3
sudo ln -sf $(pwd)/virtualenv/bin/ceph-deploy /sbin
cd $cdir
dev=sdb
[ "`sudo virt-what`" == "kvm" ] && dev=vdb
sudo virt-what | grep xen &> /dev/null && dev=xvdb
sudo lspci | grep 'Elastic Network Adapter' &> /dev/null && dev=nvme1n1
sudo lspci | grep 'Virtio SCSI' &> /dev/null && dev=sdb
dmidecode | grep -qi linode && dev=sdc
sudo ls -l /dev/$dev &> /dev/null || echo No device $dev, read requirements, fix and then try again
sudo ls -l /dev/$dev &> /dev/null || exit
sudo fdisk -l /dev/$dev|grep -iv disk|grep /dev/$dev &> /dev/null && echo Device $dev not empty, fix and try again
sudo fdisk -l /dev/$dev|grep -iv disk|grep /dev/$dev &> /dev/null && exit
sudo pvdisplay | grep /dev/$dev &> /dev/null && echo Device $dev not empty, fix and try again
sudo pvdisplay | grep /dev/$dev &> /dev/null && exit

sudo apt -y upgrade
sudo apt -y install ceph-mgr-dashboard ceph-mon ceph-osd ceph-mgr ceph-mds radosgw htop mc ||exit
wrkdir=`pwd`/`dirname "$0"`
ipaddr=`sudo ip route get $(sudo ip route show 0.0.0.0/0 | grep -oP "via \K\S+") | grep -oP "src \K\S+"`
uuid=`uuidgen`
sudo grep $ipaddr /etc/hosts &> /dev/null || sudo sh -c "echo $ipaddr `hostname -s` >> /etc/hosts"

[ -f ceph.conf ] || echo "[global]
fsid = $uuid
mon_initial_members = `hostname -s`
mon_host = $ipaddr
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
max_open_files = 131072
#rbd_default_features = 5
osd_pool_default_size = 1

[mon]
mon_compact_on_start = true
mon_allow_pool_delete = true
mgr_initial_modules = dashboard status
osd_pool_default_size = 1
mon_warn_on_pool_no_redundancy=false
" >ceph.conf

sudo ceph-deploy --overwrite-conf mon create-initial
sudo /bin/cp ceph.client.admin.keyring /etc/ceph/
sudo ceph-deploy --overwrite-conf mgr create `hostname -s`
sudo ceph-deploy --overwrite-conf mds create `hostname -s`
sudo ceph-deploy --overwrite-conf rgw create `hostname -s`
sudo ceph-deploy --overwrite-conf osd create --data /dev/$dev --dmcrypt `hostname -s`
sudo ceph mgr module enable dashboard
sudo ceph dashboard set-login-credentials ceph ceph &> /dev/null
sudo ceph dashboard create-self-signed-cert  &> /dev/null
sudo ceph mgr module disable dashboard
sudo ceph mgr module enable dashboard
sudo radosgw-admin user create --uid=sysadmin --display-name=sysadmin --system
acckey=$(sudo radosgw-admin user info --uid=sysadmin | grep access_key|cut -d '"' -f 4)
seckey=$(sudo radosgw-admin user info --uid=sysadmin | grep secret_key|cut -d '"' -f 4)
sudo ceph dashboard set-rgw-api-access-key $acckey &>/dev/null
sudo ceph dashboard set-rgw-api-secret-key $seckey &>/dev/null
sudo ceph osd pool create rbd 16
sudo ceph osd pool create cephfs 16
sudo ceph osd pool create cephfsmeta 8
sleep 3
sudo ceph osd pool application enable rbd rbd
sudo ceph osd pool application enable cephfs cephfs
sudo ceph osd pool application enable cephfsmeta cephfs
sudo ceph fs new cephfs cephfsmeta cephfs
ceph config set mon auth_allow_insecure_global_id_reclaim false
sleep 5
clear
sudo ceph -s
sudo ceph df
sudo ceph fs status
