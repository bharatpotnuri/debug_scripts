#!/bin/bash

#echo N | sudo tee /sys/module/printk/parameters/time

#rm -rf /tcb_*
#rm -rf /flowc_*
rm -rf /sq_ctx_file_*
rm -rf /cq_ctx_file_*

echo 1 > /sys/module/iw_cxgb4/parameters/debug_print

dmesg | grep "SQ: id"
while [ $? -ne 0 ]
do
	sleep 1
	dmesg | grep "SQ: id"
done

dmesg > /tmp/dmesg_dump_q_stats

cat /sys/kernel/debug/iw_cxgb4/0000\:01\:00.4/qps | grep tid > /tid_qp
ntid=`cat /tid_qp | wc -l`
awk '{print $15}' /tid_qp > /tid_awk

grep "CQ: " /tmp/dmesg_dump_q_stats > /cq_dmesg
awk '{print $6}' /cq_dmesg > /cq_id_awk

#grep "SQ: id" /tmp/dmesg_dump_q_stats > /sw_wr
awk '{print $5}' /tid_qp > /sq_id_awk

k=0
for i in $(cat /sq_id_awk)
do
  arr_sq_id[$k]=$i
	cxgbtool ens11f4 context egress $i > /sq_ctx_file_$i
  k=$((k+1))
done

k=0
for i in $(cat /cq_id_awk)
do
  arr_cq_id[$k]=$i
	cxgbtool ens11f4 context ingress $i > /cq_ctx_file_$i
  k=$((k+1))
done

k=0
for i in $(cat /tid_awk)
do
  arr_tid[$k]=$i
	/t4fwdebugtool /sys/kernel/debug/cxgb4/0000\:01\:00.4/ flowc $i > /flowc_$i
  k=$((k+1))
done

k=0
for i in `seq 1 $ntid`
do
	/root/t5tools/dumptcb6.py -i ens11f4 -t ${arr_tid[$k]} > /tcb_${arr_tid[$k]}
  k=$((k+1))
done

k=0
for i in `seq 1 $ntid`
do
	cidx=$(grep "CIDX:" /sq_ctx_file_${arr_sq_id[$k]} | awk '{print $2}')
	pidx=$(grep "PIDX:" /sq_ctx_file_${arr_sq_id[$k]} | awk '{print $2}')
	wq_pid=$(grep "SQ: id ${arr_sq_id[$k]}" /tmp/dmesg_dump_q_stats | awk '{print $15}')

	if [[ $cidx -ne $pidx ]]||[[ $cidx -ne $wq_pid ]] ; then
		echo "CIDX/PIDX != wq_PIDX:: SQ ${arr_sq_id[$k]}: hw_cidx $cidx hw_pidx $pidx wq_pidx $wq_pid tid ${arr_tid[$k]}"
	fi
	k=$((k+1))
done

echo "Total WRs in SQs = $(grep "sq_wptr " /tmp/dmesg_dump_q_stats | wc -l)"
echo "Unsignalled WRs in SQs = $(grep "sq_wptr " /tmp/dmesg_dump_q_stats | grep "signaled 0"|wc -l)"

# Search for Signalled WRs, As unsignalled WRs should be followed by signalled WRs to know the status of Un signalled WRs.
echo "Signalled WRs in SQs = $(grep "sq_wptr " /tmp/dmesg_dump_q_stats | grep "signaled 1"|wc -l)"
echo "CQs with unprocessed CQEs = $(grep "notempty 1" /tmp/dmesg_dump_q_stats | wc -l)"
echo "SQs with pending WRs = $(grep "SQ: id" /tmp/dmesg_dump_q_stats | grep -v "in_use 0"|wc -l )"

#echo Y | sudo tee /sys/module/printk/parameters/time
