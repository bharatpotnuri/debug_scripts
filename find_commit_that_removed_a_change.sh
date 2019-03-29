#!/bin/bash
set -e

if [[ $# != 2 ]]; then
	echo -e "help:"
	echo -e "\tProvide good and bad commits"
	echo -e "\tSyntax: sh find_commit_that_removed_a_change.sh <old commit> <tot commit>"
	exit 0
fi

rm -rf ./bisect_log.txt
bisect_end=0

git bisect start
git bisect good $1
git bisect bad $2 >> ./bisect_log.txt
echo " " >> ./bisect_log.txt

while [[ $bisect_end == 0 ]]
do
	hit=`grep -nir "match_device" providers/bnxt_re/main.c | wc -l`
	if [[ $hit != 0 ]]; then
		git bisect good >> ./bisect_log.txt
	else
		git bisect bad >> ./bisect_log.txt
	fi
	
	bisect_end=`cat ./bisect_log.txt | grep -i "is the first bad commit" | wc -l`
	echo " " >> ./bisect_log.txt
done

git bisect reset

