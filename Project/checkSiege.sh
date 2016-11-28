#!/bin/bash
for i in `seq 1 6`
        do
                echo "testando siege"
                sshpass -p 'vagrant' ssh root@192.168.0.$i 'siege -c 100 192.168.10.201 '  &
                echo 'Cliente' $i 'ok'
done

