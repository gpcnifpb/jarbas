#!/bin/bash
for i in `seq 1 6`
        do
                echo "gitpull"
                sshpass -p 'vagrant' ssh root@192.168.0.$i 'siege'
                echo 'Cliente' $i 'ok'
done

