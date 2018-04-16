#!/bin/bash

#
## This is a simple program to print out the SW SQ entries by 
## dissecting the fields. SW SQ should be dumped in Hex format 
## Ex: crash: x/<size of whole queue in bytes>xb 0x<start address> 
#

if [[ $# != 1 ]]; then
  echo "Usage: #extract_cqe_from_sw_sq.sh <sw SQ dumped in hex, 8 bytes per line>"
	echo "Ex dump: 0xffff880820fc0058:	0x30	0xc8	0x4a	0x2c	0x08	0x88	0xff	0xff"
  exit
fi

filename="$1"

echo -n > /tmp/cqe_from_sw_sq.txt

read -r line < $filename
base_addr=`echo $line | awk '{print $1}'`
base_addr=${base_addr::-1}
man_addr=$base_addr
#printf "0x%x  0x%x\n" $man_addr $base_addr

#echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/cqe_from_sw_sq.txt
#echo "Note: Struct members are in Little Endian, So while reading " >> /tmp/cqe_from_sw_sq.txt
#echo -e "\tmultibyte data, read it from right to left" >> /tmp/cqe_from_sw_sq.txt
#echo "Example:" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t A multi byte data 0x01234567 is stored at address 0x100 as" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t Little Endian:" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t \t  0x67  0x45  0x23  0x01" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t Big Endian:" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t \t 0x100 0x101 0x102 0x103" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t \t  0x01  0x23  0x45  0x67" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t ToDo : Print them in reverse so that the above need not be done" >> /tmp/cqe_from_sw_sq.txt
#echo -e "\t ToDo : Add parsing logic, say opcode, cqe processing etc" >> /tmp/cqe_from_sw_sq.txt
#echo -e "-------------------------------------------------------------------------------------------------" >> /tmp/cqe_from_sw_sq.txt
#echo -e ""  >> /tmp/cqe_from_sw_sq.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
#read -r line < $filename
	line_addr=`echo $line | awk '{print $1}'`
	line_addr=${line_addr::-1}

	index=$(((($line_addr - $base_addr) / 8) % 11))
	#printf "0x%x   0x%x\n" $base_addr $line_addr
	index=$(($index % 11))
	#echo "index $index" >> /tmp/cqe_from_sw_sq.txt
	
	case $index in
		0)
			man_addr=$(($man_addr + 0)) #some crazy hack
			;;
		1)
			echo $line | awk -v pat="$man_addr" '{$1=sprintf("0x%x:", pat); print $0}' >> /tmp/cqe_from_sw_sq.txt
			man_addr=$(($man_addr + 8))
			;;
		2)
			echo $line | awk -v pat="$man_addr" '{$1=sprintf("0x%x:", pat); print $0}' >> /tmp/cqe_from_sw_sq.txt
			man_addr=$(($man_addr + 8))
			;;
		3)
			echo $line | awk -v pat="$man_addr" '{$1=sprintf("0x%x:", pat); print $0}' >> /tmp/cqe_from_sw_sq.txt
			man_addr=$(($man_addr + 8))
			;;
		4)
			echo $line | awk -v pat="$man_addr" '{$1=sprintf("0x%x:", pat); print $0}' >> /tmp/cqe_from_sw_sq.txt
			man_addr=$(($man_addr + 8))
			;;
		5)
			;;
		6)
			;;
		7)
			;;
		8)
			;;
		9)
			;;
		10)
			;;
	esac
done < "$filename"



