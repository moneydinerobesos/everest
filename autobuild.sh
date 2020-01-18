#!/bin/sh
if [ "$#" -eq 0 ] ; then
  echo "Usage: $0 <profile>" 1>&2
  exit 1
fi

SUDO=
if [ "$EUID" -ne 0 ]; then
  SUDO=sudo
fi

PROFILE=$1
STAGE3_URL=`./do.ts determine-latest-stage3`
STAGE3_HASH=`./do.ts download --hash $STAGE3_URL`
STAGE3_FILE=cache/download/$STAGE3_HASH
echo "Stage3 tarball is $STAGE3_URL ."
$SUDO ./do.ts download "$STAGE3_URL" || exit 1

GENTOO_DIR=gentoo/$PROFILE

[ -f "${GENTOO_DIR}/done" ] && DONE=$(cat "${GENTOO_DIR}/done")

if [ "$DONE" != "$STAGE3_HASH" ]; then
  echo "Initializing $GENTOO_DIR ..."
  $SUDO rm -rf "$GENTOO_DIR"
  $SUDO mkdir -p $GENTOO_DIR
  echo "Extracting stage3..."
  $SUDO tar xpf $STAGE3_FILE -C $GENTOO_DIR || exit 1
  $SUDO mkdir -p $GENTOO_DIR/var/db/repos/gentoo || exit 1
fi

$SUDO cp /etc/resolv.conf $GENTOO_DIR/resolv.conf
$SUDO mkdir -p $GENTOO_DIR/etc/kernels
$SUDO ln -f profile/$PROFILE/package.keywords $GENTOO_DIR/etc/portage/package.keywords
$SUDO ln -f profile/$PROFILE/package.license $GENTOO_DIR/etc/portage/package.license
$SUDO ln -f profile/$PROFILE/package.use $GENTOO_DIR/etc/portage/package.use/$PROFILE
if [ -f profile/$PROFILE/package.mask ]; then
	$SUDO ln -f profile/$PROFILE/package.mask $GENTOO_DIR/etc/portage/package.mask
fi

if [ -f profile/$PROFILE/package.provided ]; then
	$SUDO mkdir -p $GENTOO_DIR/etc/portage/profile
	$SUDO ln -f profile/$PROFILE/package.provided $GENTOO_DIR/etc/portage/profile/package.provided
fi

$SUDO mkdir -p $GENTOO_DIR/etc/portage/sets
$SUDO ln -f profile/$PROFILE/set $GENTOO_DIR/etc/portage/sets/all

if [ -f profile/$PROFILE/set-pre ]; then
	$SUDO ln -f profile/$PROFILE/set-pre $GENTOO_DIR/etc/portage/sets/all-pre
fi

if [ -f profile/$PROFILE/set-kernel ]; then
  $SUDO ln -f profile/$PROFILE/set-kernel $GENTOO_DIR/etc/portage/sets/kernel
fi

$SUDO ln -f profile/common/portage-bashrc $GENTOO_DIR/etc/portage/bashrc

$SUDO ln -f profile/$PROFILE/kernel-config $GENTOO_DIR/etc/kernels/kernel-config
if [ -f profile/$PROFILE/linuxrc ]; then
  $SUDO ln -f profile/$PROFILE/linuxrc $GENTOO_DIR/linuxrc
fi
touch profile/$PROFILE/rdepends
$SUDO ln -f profile/$PROFILE/rdepends $GENTOO_DIR/rdepends
$SUDO ln -f profile/common/*.sh $GENTOO_DIR/

$SUDO ./do.ts chroot --profile=$PROFILE "$GENTOO_DIR" "/build.sh" || exit 1

echo "$STAGE3_HASH" > done-$$.tmp
$SUDO mv done-$$.tmp $GENTOO_DIR/done # mark as built