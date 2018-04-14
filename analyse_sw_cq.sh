#!/bin/bash

#
## This is a simple program to print out the SW SQ entries by 
## dissecting the fields. SW SQ should be dumped in Hex format 
## Ex: crash: x/<size of whole queue in bytes>xb 0x<start address> 
#

if [[ $# != 1 ]]; then
  echo "Usage: #analyse_sw_sq.sh <sw SQ dumped in hex, 8 bytes per line>"
	echo "Ex dump: 0xffff880820fc0058:	0x30	0xc8	0x4a	0x2c	0x08	0x88	0xff	0xff"
  exit
fi

filename="$1"

echo "" > /tmp/sw_cq_dis.txt

read -r line < $filename
base_addr=`echo $line | awk '{print $1}'`
base_addr=${base_addr::-1}

echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/sw_cq_dis.txt
echo "Note: Struct members are in Big Endian, So while reading " >> /tmp/sw_cq_dis.txt
echo -e "\tmultibyte data, read it from left to right" >> /tmp/sw_cq_dis.txt
echo "Example:" >> /tmp/sw_cq_dis.txt
echo -e "\t A multi byte data 0x01234567 is stored at address 0x100 as" >> /tmp/sw_cq_dis.txt
echo -e "\t Little Endian:" >> /tmp/sw_cq_dis.txt
echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/sw_cq_dis.txt
echo -e "\t \t  0x67  0x45  0x23  0x01" >> /tmp/sw_cq_dis.txt
echo -e "\t Big Endian:" >> /tmp/sw_cq_dis.txt
echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/sw_cq_dis.txt
echo -e "\t \t  0x01  0x23  0x45  0x67" >> /tmp/sw_cq_dis.txt
echo -e "\t ToDo : Print them in reverse so that the above need not be done" >> /tmp/sw_cq_dis.txt
echo -e "\t ToDo : Add parsing logic, say opcode, cqe processing etc" >> /tmp/sw_cq_dis.txt
echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/sw_cq_dis.txt
echo -e ""  >> /tmp/sw_cq_dis.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
#read -r line < $filename
	line_addr=`echo $line | awk '{print $1}'`
	line_addr=${line_addr::-1}

	index=$(((($line_addr - $base_addr) / 8) % 4))
	#printf "0x%x   0x%x\n" $base_addr $line_addr
	index=$(($index % 11))
	#echo "index $index" >> /tmp/sw_cq_dis.txt
	
	case $index in
		0)
			echo "opcode: `echo $line | awk '{print $5}'`" >> /tmp/sw_cq_dis.txt
			echo "len: `echo $line | awk '{print ($6,$7,$8,$9)}'`" >> /tmp/sw_cq_dis.txt
			;;
		1)
			echo "flit 1: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/sw_cq_dis.txt
			;;
		2)
			echo "flit 2: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/sw_cq_dis.txt
			;;
		3)
			echo "flit 3: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/sw_cq_dis.txt
			echo >> /tmp/sw_cq_dis.txt 
			;;
	esac
done < "$filename"



