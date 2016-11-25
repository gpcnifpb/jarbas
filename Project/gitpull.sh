#!/bin/bash
	for i in `seq 1 16`
    	do
      		echo "gitpull"
      		sshpass -p 'vagrant' ssh root@192.168.0.$i 'cd /home/vagrant/jarbas && git pull && git checkout master-testing ' 
		echo 'Máquina' $i 'ok' 
    	done

sshpass -p 'vagrant' ssh root@192.168.0.200 'cd /gpcn/atacado/scripts/jarbas && git pull && git checkout master-testing'
sshpass -p 'vagrant' ssh root@192.168.10.201 'cd /gpcn/monitorado/scripts/jarbas && git pull && git checkout master-testing'  

