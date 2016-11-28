for i in `seq 1 6`
    	do
      		echo "gitpull"
      		sshpass -p 'vagrant' ssh root@192.168.0.$i 'cd /gpcn/clientes/logs/ping && rm -r * '
		echo 'Cliente' $i 'ok'
done

sshpass -p 'vagrant' ssh root@192.168.0.200 'cd /gpcn/atacado/logs/collectl && rm -R * && cd /gpcn/atacado/logs/netstat && rm -R * && cd /gpcn/atacado/logs/sysbench && rm -R * '
echo "atacado ok"
sshpass -p 'vagrant' ssh root@192.168.10.201 'cd /gpcn/monitorado/logs/collectl && rm -R * && cd /gpcn/monitorado/logs/netstat && rm -R * && cd /gpcn/monitorado/logs/sysbench && rm -R * '
echo "monitorado ok"
sshpass -p 'vagrant' ssh root@10.0.4.186 'cd /root/gpcn/xenserver/log/eth1/ && rm -rf * && cd /root/gpcn/xenserver/log/vif6/ && rm -rf * && cd /root/gpcn/xenserver/log/vmstat/ && rm -rf * && cd /root/gpcn/xenserver/log/vif7/ && rm -rf *'
echo "xen ok"

