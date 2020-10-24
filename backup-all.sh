#!/bin/bash

# zip sql files

declare -a list
declare -a filename
date=`date +%y%m%d`
for file in *.sql
do
	list=(${list[*]} "$file")
	filename=(`basename -s .sql $file`)
	echo "ITEM WILL BE ZIPPED: ${file[@]}"
	zip -e "${filename%/}.zip" "$file"
done

#backup zip files

for backup_file in *.zip
do
	cp -rf $backup_file $PWD/${backup_file%.zip}-backup-${date}.zip
done
