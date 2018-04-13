#!/bin/bash

while true
do
	read_err=0
	read_err=$(dmesg | grep "Request device" | wc -l)
	echo "$read_err"
	if [[ $read_err -ne 0 ]]
	then
		echo "inside $read_err"
		cat /sys/kernel/debug/cxgb4/0000\:02\:00.4/devlog | grep "ERR" | grep "CORE" | grep "flowc" > devlog.txt
		awk '{print $9}' devlog.txt > eq_id_awk
		i=0
		k=0
		for i in $(cat eq_id_awk)
		do
			i=${i::-1}
			if [ $i != $k ]
			then
				dmesg -c | grep "Request device" >> eq_ctx_file_$i
				cxgbtool enp2s0f4 context egress $i >> eq_ctx_file_$i
				k=$i
				echo "#### context for EQ $i dumped above ^^^ ####" >> eq_ctx_file_$i
				echo "i = $i k = $k"
			fi
		done
	fi
	dmesg -c
	sleep 0.1
done

