#!/bin/bash
########################################
# Should be run on Node/Rank 0
########################################

cidx=./cidx
pidx=./pidx
k=0
np_by_two=0	  # max value of first half of ranks of test is run on two nodes
mpi_dump=/tmp # or the path to mpi output dumps
cd $mpi_dump/

# search the CQs dumped for notempty 0 => this means all the CQs are completely drained out and all cqes are processed.
echo "CQs with unprocessed CQEs = $(grep "notempty 1" $mpi_dump/mpi.* | wc -l)"

# Search the SQs for pending WRs
echo "SQs with pending WRs = $(grep "SQ: id" $mpi_dump/mpi.*|grep -v "in_use 0"|wc -l )"

# Check those SQs
#echo "SQs with pending WRs are:"
#grep "SQ: id" $mpi_dump/mpi.*|grep -v "in_use 0"

# Search for one SQ for Example
echo "Example SQs of process 0:"
echo "$(grep -n "SQ: id" $mpi_dump/mpi.1.*|grep -v "in_use 0")"

# Search for Un-Signalled WRs
echo "Total WRs in SQs = $(grep "sq_wptr " $mpi_dump/mpi*|wc -l)"
echo "Unsignalled WRs in SQs = $(grep "sq_wptr " $mpi_dump/mpi*|grep "signaled 0"|wc -l)"

# Search for Signalled WRs, As unsignalled WRs should be followed by signalled WRs to know the status of Un signalled WRs.
echo "Signalled WRs in SQs = $(grep "sq_wptr " $mpi_dump/mpi*|grep "signaled 1"|wc -l)"
#grep "sq_wptr " $mpi_dump/mpi*|grep "signaled 1"

# Now start 
rm -f ./sw_wr ./sq_id_awk ./sq_ctx_* ./tcb_*

#grep "sq_wptr " $mpi_dump/mpi*|grep "signaled 0" > ./sw_wr

#grep "SQ: id" $mpi_dump/mpi.*|grep -v "in_use 0" > ./sw_wr
grep "SQ: id" $mpi_dump/mpi.* > ./sw_wr
awk '{print $4}' sw_wr > ./sq_id_awk
awk '{print $16}' sw_wr > ./wq_pid_awk
#grep -o "mpi.*" sw_wr | awk '{print substr($1,7,2)}' > ./mpi_rank_awk   #if np > 9
grep -o "mpi.*" sw_wr | awk '{print substr($1,7,1)}' > ./mpi_rank_awk    #if np < 9

for i in $(cat wq_pid_awk)
do
	i=${i#0}  # Remove possible leading zero."Shortest Substring Match"
	arr_wq_pid[$k]=$i
	k=$((k+1))
done

k=0
for i in $(cat mpi_rank_awk)
do
	#i=${i#0}  # Remove possible leading zero."Shortest Substring Match" needed if np > 9 00 -> 0, 01 -> 1..etc
	arr_mpi_rank[$k]=$i
	k=$((k+1))
done

echo "Printing Findouts ::"

k=0
i=0

for i in $(cat sq_id_awk)
do
	sq_ctx_file=sq_ctx_$i

	if [[ ${arr_mpi_rank[$k]} -le $np_by_two ]]
	then
		echo "### this node ####"
		cxgbtool eth7 context egress $i > $sq_ctx_file
	else
		echo "### other peer ####"
		ssh root@10.193.184.162 cxgbtool eth7 context egress $i > $sq_ctx_file
	fi
	
	#grep 'CIDX:\|PIDX:' sq_ctx*
	cidx=$(grep "CIDX:" $sq_ctx_file|awk '{print $2}')
	pidx=$(grep "PIDX:" $sq_ctx_file|awk '{print $2}')
	tid=$(grep "uPToken:" $sq_ctx_file|awk '{print $2}')

	#echo "CIDX/PIDX != wq_PIDX:: SQ $i: hw_cidx $cidx hw_pidx $pidx tid $tid wq_pidx ${arr_wq_pid[$k]} mpi_rank ${arr_mpi_rank[$k]}"
	
	if [[ $cidx -ne $pidx ]]||[[ $cidx -ne ${arr_wq_pid[$k]} ]] ; then
		echo "CIDX/PIDX != wq_PIDX:: SQ $i: hw_cidx $cidx hw_pidx $pidx tid $tid wq_pidx ${arr_wq_pid[$k]} mpi_rank ${arr_mpi_rank[$k]}"
	fi

	tcb_file=tcb_$tid
	if [[ ${arr_mpi_rank[$k]} -le $np_by_two ]]
	then
		/root/t5tools/dumptcb5.py -i eth7 -t $tid > $tcb_file
	else
		ssh root@10.193.184.162 /root/t5tools/dumptcb5.py -i eth7 -t $tid > $tcb_file
	fi

	#grep "snd_una" $tcb_file
	snd_una=$(grep "snd_una" $tcb_file|awk '{print substr($2,1,1)}')
	snd_nxt=$(grep "snd_nxt" $tcb_file|awk '{print substr($4,1,1)}')
	snd_max=$(grep "snd_max" $tcb_file|awk '{print substr($6,1,1)}')
	
	if [[ $snd_una -ne $snd_nxt ]]||[[ $snd_una -ne $snd_max ]] ; then
		echo "snd_nxt/snd_una/snd_max NOT EQUAL ::"
		echo "SQ $i: snd_una $snd_una snd_nxt $snd_nxt snd_max $snd_max tid $tid mpi_rank ${arr_mpi_rank[$k]}"
	fi
	
	k=$((k+1))
done

