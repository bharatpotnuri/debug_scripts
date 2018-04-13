#!/bin/bash
cat /root/mpd.hosts
sleep 4
np=2
i=1
exponent=7

while [[ $i -le $exponent ]]
do
	{
		echo "###############  i = $i  ###################"
		echo "############### np = $np ###################"
		/usr/mpi/gcc/openmpi-2.0.0/bin/mpirun -np $np --hostfile /root/mpd.hosts --allow-run-as-root --mca btl_openib_if_exclude eth4,eth1--mca btl openib,sm,self /usr/mpi/gcc/openmpi-2.0.0/tests/IMB/IMB-MPI1
		np=$((np*2))
		i=$((i+1))
	}
done

