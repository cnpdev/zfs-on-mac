#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <pool> <disk1> <disk2>
Create a ZFS pool that mirrors two volumes
END
)

if [[ $# -ne 3 ]] ; then
  echo "$USAGE"
  exit -1
fi

POOL=$1
VOLUME1_UUID=$2
VOLUME2_UUID=$3


# The volumes must be unmounted before zpool create.
/usr/sbin/diskutil unmount $VOLUME1_UUID || true
/usr/sbin/diskutil unmount $VOLUME2_UUID || true

# Create the ZFS mirror pool.
/usr/bin/sudo /usr/local/bin/zpool create -f \
  -o ashift=12 \
  -O casesensitivity=insensitive \
  -O normalization=formD \
  -O compression=lz4 \
  -O atime=off \
  -O cachefile=$PWD/zpool.cache \
  $POOL \
  mirror \
  /var/run/disk/by-id/media-$VOLUME1_UUID \
  /var/run/disk/by-id/media-$VOLUME2_UUID

# Notes:
#
# ashift=12 
#   Use 4K sectors.
#   See http://wiki.illumos.org/display/illumos/ZFS+and+Advanced+Format+disks
#
# casesensitivity=insensitive
#   Recommended for Mac OS X. Some applications won't work without it.
#
# normalization=formD
#   Recommended for Mac OS X. Some applications won't work without it.
#
# compression=lz4
#   The lz4 compression algorithm is a high-performance replacement for the lzjb
#   algorithm. It features significantly faster compression and decompression,
#   as well as a moderately higher compression ratio than lzjb,
#
# atime=off
#   Controls whether the access time for files is updated when they are read.
#   Turning this property off avoids producing write traffic when reading files
#   and can result in signif icant performance gains, though it might confuse
#   mailers and other similar utilities.
