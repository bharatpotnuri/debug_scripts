#!/bin/bash

cidx=./cidx
pidx=./pidx
k=0
mpi_dump=/tmp/ # or the path to mpi output dumps
cd $mpi_dump/

# search the CQs dumped for notempty 1 => this means all the CQs are completely drained out and all cqes are processed.
echo "CQs with unprocessed CQEs = $(grep "notempty 1" $mpi_dump | wc -l)"

# Search the RQs for pending WRs
echo "RQs with pending WRs = $(grep "RQ: id" $mpi_dump/mpi.*|grep -v "in_use 0"|wc -l )"

# Search for one RQ for Example
echo "Example RQs of process 0:"
echo "$(grep -n "RQ: id" $mpi_dump/mpi.1.00|grep -v "in_use 0")"

# Now start 
rm -f ./rw_wr ./rq_id_awk ./rq_ctx_*


#grep "RQ: id" $mpi_dump/mpi.*|grep -v "in_use 0" > ./sw_wr
grep "RQ: id" $mpi_dump/mpi.* > ./rw_wr
awk '{print $4}' rw_wr > ./rq_id_awk
awk '{print $16}' rw_wr > ./wq_rq_pid_awk
grep -o "mpi.*" rw_wr | awk '{print substr($1,7,2)}' > ./mpi_rank_rq_awk

for i in $(cat wq_rq_pid_awk)
do
	i=${i#0}
	arr_wq_pid[$k]=$i
	k=$((k+1))
done

k=0
for i in $(cat mpi_rank_rq_awk)
do
	i=${i#0}
	arr_mpi_rank[$k]=$i
	k=$((k+1))
done

echo "Printing Findouts ::"

k=0
i=0

for i in $(cat rq_id_awk)
do
	rq_ctx_file=rq_ctx_$i
	
	if [[ ${arr_mpi_rank[$k]#0} -le 31 ]]
	then
		ssh root@10.193.184.162 cxgbtool eth7 context egress $i > $rq_ctx_file
	else
		cxgbtool eth7 context egress $i > $rq_ctx_file
	fi
	
	#grep 'CIDX:\|PIDX:' rq_ctx*
	cidx=$(grep "CIDX:" $rq_ctx_file|awk '{print $2}')
	pidx=$(grep "PIDX:" $rq_ctx_file|awk '{print $2}')

#	echo "CIDX/PIDX != wq_PIDX:: RQ $i: hw_cidx $cidx hw_pidx $pidx tid $tid wq_pidx ${arr_wq_pid[$k]} mpi_rank ${arr_mpi_rank[$k]}"
	
	if [[ $cidx -ne $pidx ]]||[[ $cidx -ne ${arr_wq_pid[$k]} ]] ; then
		echo "CIDX/PIDX != wq_PIDX:: RQ $i: hw_cidx $cidx hw_pidx $pidx tid $tid wq_pidx ${arr_wq_pid[$k]} mpi_rank ${arr_mpi_rank[$k]}"
	fi

	k=$((k+1))
done

