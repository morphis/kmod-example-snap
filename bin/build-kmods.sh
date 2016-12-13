#!/bin/bash
set -ex

need_build=0
kversion=`uname -r`

load_kmod() {
	rmmod ashmem_linux || true
	rmmod binder_linux || true
	insmod $1/ashmem_linux.ko
	insmod $1/binder_linux.ko
}

if [ ! -e $SNAP_COMMON/$kversion ] ; then
	need_build=1
else
	load_kmod $SNAP_COMMON/$kversion
fi

if [ $need_build -eq 0 ]; then
	echo "No rebuild needed"
	exit 0
fi

$SNAP/bin/classic-create || true

rm -rf $SNAP_COMMON/classic/build
mkdir -p $SNAP_COMMON/classic/build
cp -rav $SNAP/src/* $SNAP_COMMON/classic/build/

cat<<EOF > $SNAP_COMMON/classic/build/run.sh
#!/bin/sh
set -ex
apt update
apt install -y --force-yes linux-headers-`uname -r` build-essential
cd /build/ashmem
make
cd /build/binder
make
EOF

chmod +x $SNAP_COMMON/classic/build/run.sh
$SNAP/bin/classic /build/run.sh

mkdir -p $SNAP_COMMON/$kversion
cp $SNAP_COMMON/classic/build/ashmem/ashmem_linux.ko $SNAP_COMMON/$kversion/
cp $SNAP_COMMON/classic/build/binder/binder_linux.ko $SNAP_COMMON/$kversion/
load_kmod $SNAP_COMMON/$kversion
