#!/bin/bash
#echo "num args $#"
if [[ $# != 2 ]]; then
	echo "Usage: #compare_commit.sh <what_file_to_compare> <with_what>"
	exit
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
#		echo $line
		echo $line | awk '{$1=""; $2=""; print $0}' > /tmp/line
		sed -i 's/^ *//' /tmp/line
		line=`cat /tmp/line | awk '{print $0}'`
		line=${line::-2}
#		echo $line
		grep --silent -F "$line" $2 
		if [[ $? == 0 ]]; then
			search="Yes"
		else
			search="No"
		fi
    echo -e "Commit:: $line \t\t\t\t-> $search"
done < "$1"



