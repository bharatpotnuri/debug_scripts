#!/bin/sh
#
# The firmware image name must be of the form foo-a.b.c.d.bin
#
# Examples:
#
# bin2hc.sh t4fw-1.2.40.0.bin t4_fw.h t4_fw.c
# t4_fw.h will have FW_VERSION_XXX, extern fw_data[], extern fw_size.
#
# bin2hc.sh t4fw-1.2.40.0.bin t4_fw.h t4_fw.c T4FOO
# t4_fw.h will have T4FOO_VERSION_XXX, extern t4foo_data[], extern t4foo_size.

if [ ! -r "$1" ]; then
 echo "cannot read input file $1"
 exit 1
fi
BFILE=$1
HFILE=${2:-/dev/stdout}
CFILE=${3:-/dev/stdout}
PREFIX=${4:-FW}
prefix=`echo $PREFIX | /usr/bin/tr '[:upper:]' '[:lower:]'`

exec > $HFILE
cat << EOF
/*
 * Automatically generated file.
 */

#ifndef __${PREFIX}_H
#define __${PREFIX}_H

EOF
basename "$BFILE" | awk '{
split($0, a, "-");
split(a[2], b, ".");
printf "#define %s_VERSION_MAJOR %s\n", PREFIX, b[1];
printf "#define %s_VERSION_MINOR %s\n", PREFIX, b[2];
printf "#define %s_VERSION_MICRO %s\n", PREFIX, b[3];
printf "#define %s_VERSION_BUILD %s\n", PREFIX, int(b[4]);
}' PREFIX="$PREFIX"
cat << EOF

extern unsigned char ${prefix}_data[];
extern int ${prefix}_size;

#endif
EOF

exec > $CFILE
cat << EOF
/*
 * Automatically generated file.
 */

unsigned char ${prefix}_data[] = {
EOF
od -v -An -tx1 $BFILE | sed 's/\([0-9a-f][0-9a-f]\)/0x\1,/g'
cat << EOF
};
int ${prefix}_size = sizeof(${prefix}_data);
EOF
