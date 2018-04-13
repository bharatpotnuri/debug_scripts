#!/bin/bash

rm -rf /tcb_*
rm -rf /flowc_*
rm -rf /sq_ctx_file_*
rm -rf /cq_ctx_file_*

m=0
for m in `seq 1 10`
do 
	cat /sys/kernel/debug/iw_cxgb4/0000\:01\:00.4/qps | grep tid > /tid_qp
	ntid=`cat /tid_qp | wc -l`
	awk '{print $15}' /tid_qp > /tid_awk
	
	cat /sys/kernel/debug/cxgb4/0000\:01\:00.4/cim_la > cim_la_$m
	
	k=0
	for i in $(cat /tid_awk)
	do
	  arr_tid[$k]=$i
	  /t4fwdebugtool /sys/kernel/debug/cxgb4/0000\:01\:00.4/ flowc $i > /flowc_$i\_$m
	  k=$((k+1))
	done
	
	k=0
	for i in `seq 1 $ntid`
	do
	  /root/t5tools/dumptcb6.py -i ens11f4 -t ${arr_tid[$k]} > /tcb_${arr_tid[$k]}\_$m
	  k=$((k+1))
	done
	
	sleep .5
done
sh dump_and_process_flowc_q_contexts.sh
