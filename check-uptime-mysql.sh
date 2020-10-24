#!/bin/bash

service=mysql
date=$(date +"%m-%d-%Y-%r")

if ps ax | grep -v grep | grep $service > /dev/null
then
echo "$date   $service service is running!!!" 
else
echo "$date   $service service is stopped!!!" >> $HOME/mysql.log 2>&1
/etc/init.d/$service start >> $HOME/mysql.log 2>&1
echo "$date   $service service is started!!!" >> $HOME/mysql.log 2>&1
fi
