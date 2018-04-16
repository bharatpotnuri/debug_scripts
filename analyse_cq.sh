#!/bin/bash

#
## This is a simple script to print out the HW/SW CQ entries by 
## dissecting the fields. CQ should be dumped in Hex format 
## Ex: crash: x/<size of whole queue in bytes>xb 0x<start/base address> 
#

if [[ $# != 1 ]]; then
  echo "Usage: #analyse_cq.sh <HW/SW CQ dumped in hex, 8 bytes per line>"
	echo "Ex dump: 0xffff880820fc0058:	0x30	0xc8	0x4a	0x2c	0x08	0x88	0xff	0xff"
	echo "Output is dumped to '/tmp/cq_dis.txt'"
  exit
fi

filename="$1"

echo "" > /tmp/cq_dis.txt

read -r line < $filename
base_addr=`echo $line | awk '{print $1}'`
base_addr=${base_addr::-1}

echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/cq_dis.txt
echo "Note: Struct members are in Big Endian, So while reading " >> /tmp/cq_dis.txt
echo -e "\tmultibyte data, read it from left to right" >> /tmp/cq_dis.txt
echo "Example:" >> /tmp/cq_dis.txt
echo -e "\t A multi byte data 0x01234567 is stored at address 0x100 as" >> /tmp/cq_dis.txt
echo -e "\t Little Endian:" >> /tmp/cq_dis.txt
echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/cq_dis.txt
echo -e "\t \t  0x67  0x45  0x23  0x01" >> /tmp/cq_dis.txt
echo -e "\t Big Endian:" >> /tmp/cq_dis.txt
echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/cq_dis.txt
echo -e "\t \t  0x01  0x23  0x45  0x67" >> /tmp/cq_dis.txt
echo -e ""  >> /tmp/cq_dis.txt
echo -e "\t ToDo : Add parsing logic, say opcode, cqe processing etc" >> /tmp/cq_dis.txt
echo -e "\t ToDo : Parse the other flits to extract TAG, MSN etc" >> /tmp/cq_dis.txt
echo -e "\t Note/Todo : SW repo code CQE has RSS header as flit0 but upstream code CQE has no RSS header," >> /tmp/cq_dis.txt
echo -e "\t        This script is for now only to be used with upstream code CQE" >> /tmp/cq_dis.txt
echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/cq_dis.txt
echo -e ""  >> /tmp/cq_dis.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
#read -r line < $filename
	line_addr=`echo $line | awk '{print $1}'`
	line_addr=${line_addr::-1}

	index=$(((($line_addr - $base_addr) / 8) % 4))
	#printf "0x%x   0x%x\n" $base_addr $line_addr
	index=$(($index % 11))
	#echo "index $index" >> /tmp/cq_dis.txt
	
	case $index in
		0)
			echo "CQE $line_addr" >> /tmp/cq_dis.txt

			pr1="`echo $line | awk '{print $5}'`"
			echo "Opcode: $(($pr1 & 0xF))" >> /tmp/cq_dis.txt						# bits 0-3 of first be32 of flit0

			echo "Type: $((($pr1 & 0x10) >> 4))" >> /tmp/cq_dis.txt							# bit 4 of first be32 of flit0

			pr2="`echo $line | awk '{print $4}'`"
			pr2=$((($pr2 << 0x8) + pr1))
			echo "Status: $((($pr2 & 0x3e0) >> 0x5))" >> /tmp/cq_dis.txt	#bits 5-9 of first be32 of flit0

			echo "Generation bit: $((($pr2 & 0x400) >> 0xa))" >> /tmp/cq_dis.txt	#bit 10 of first be32 of flit0
			
			pr3="`echo $line | awk '{print $3}'`"
			pr4="`echo $line | awk '{print $2}'`"
			pr4=$((($pr4 << 0x18) + ($pr3 << 0x10) + pr2))
			echo "QPID: $((($pr4 & 0xFFFFF000) >> 0xc))" >> /tmp/cq_dis.txt	#bit 12-31 of first be32 of flit0

			echo "len: `echo $line | awk '{print ($6,$7,$8,$9)}'`" >> /tmp/cq_dis.txt	#second be32 of flit0
			;;
		1)
			echo "flit 1: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/cq_dis.txt
			;;
		2)
			echo "flit 2: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/cq_dis.txt
			;;
		3)
			echo "flit 3: `echo $line | awk '{$1=""; print $0}'`" >> /tmp/cq_dis.txt
			echo >> /tmp/cq_dis.txt 
			;;
	esac
done < "$filename"



