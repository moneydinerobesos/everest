#!/bin/sh
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

ROOTDIR=`dirname $0`
CHROOT="../../chroot ${ROOTDIR}"
wget -O - `../../find_latest_stage3 i686` | tar jxvpf - -C "${ROOTDIR}" -k -P
sed -i 's/^\(CFLAGS=.\+\)"$/\1 -mno-tls-direct-seg-refs"/' ${ROOTDIR}/etc/portage/make.conf
$CHROOT emerge -uDN world || exit 1
#$CHROOT "eselect python set python2.7"