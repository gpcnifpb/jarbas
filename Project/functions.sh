#!/bin/bash

##################################################################
# Objetivo: Executa o experimento por completo.
# Argumentos:
#   $1 -> Numero de rodadas
#   $2 -> Exit status (optional)
##################################################################
function run() {
  echo "Executar função com $1 rodadas"
  numRodadas="$1"

  for r in `seq 1 $numRodadas`
  do
    echo "RUN LOOP, RODADA: $r"
    runSemAtaque $r
    echo "AINDA NA RODADA $r"
    runComAtaque $r
  done

}

##################################################################
# Objetivo: Checar ping com a máquina
# Argumentos:
#   $1 -> Numero de Clientes
#   $2 -> Numero de Slaves)
##################################################################
function pingCheck() {

	NUMCLIENTS="$1"
	NUMSLAVES="$2"

	ping -c1 192.168.0.200 > /dev/null

		if [ $? -eq 0 ]
		 then
			echo "Teste de ping para Atacado com sucesso"
		 else
			echo "Teste de ping para Atacado falhou"
			exit

		fi

	ping -c1 192.168.10.201 > /dev/null

		if [ $? -eq 0 ]
		 then
			echo "Teste de ping para Monitorado com sucesso"
		else
			echo "Teste de ping para Monitorado falhou"
			exit
		fi

	for i in `seq 1 $NUMCLIENTS`
	do
		ping -c1 192.168.0.$i > /dev/null

			if [ $? -eq 0 ]
		 	then
				echo "Teste de ping para Cliente "$i" com sucesso"
			else
				echo "Teste de ping para Cliente "$i" falhou"
				exit
			fi
	done

	for i in `seq $[NUMCLIENTS+1] $[NUMCLIENTS+NUMSLAVES]`
	do
		ping -c1 192.168.0.$i > /dev/null

			if [ $? -eq 0 ]
		 	then
				echo "Teste de ping para Atacante "$i" com sucesso"
			else
				echo "Teste de ping para Atacante "$i" falhou"
				exit
			fi
	done
}

##################################################################
# Objetivo: Executa o experimento sem ataque (Só clientes)
# Argumentos:
#   $1 -> Numero da Rodada
##################################################################
function runSemAtaque() {
	numRodada="$1"
	tipoDeExperimento="SemAtaque"
  echo "RODADA $1 SEM ATAQUE"

	echo "runAtacado"
  sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas/Project/jarbas run atacado '$numRodada $tipoDeExperimento &

  echo "runMonitorado"
  sshpass -p 'vagrant' ssh root@192.168.10.201 'bash /gpcn/monitorado/scripts/jarbas/Project/jarbas run monitorado' $numRodada $tipoDeExperimento &
  for i in `seq 1 6`
  do
    echo "runClientes"
    sshpass -p 'vagrant' ssh root@192.168.0.$i 'bash /home/vagrant/jarbas/Project/jarbas run cliente '$numRodada $tipoDeExperimento &
  done

}

##################################################################
# Objetivo: Executa o experimento com ataque (Clientes e atacantes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runComAtaque() {
  	numRodada="$1"
    tipoDeExperimento="ComAtaque"
  	echo "RODADA $1 COM ATAQUE"

    echo "runAtacado"
    sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas/Project/jarbas run atacado '$numRodadas $tipoDeExperimento
    echo "runMonitorado"
    sshpass -p 'vagrant' ssh root@192.168.0.201 'bash /gpcn/monitorado/scripts/jarbas/Project/jarbas run monitorado '$numRodadas $tipoDeExperimento

    for i in `seq 1 6`
    do
      echo "runCliente"
      sshpass -p 'vagrant' ssh root@192.168.0.$i 'bash /home/vagrant/jarbas/Project/jarbas run cliente '$numRodada $tipoDeExperimento &
    done

    for i in `seq 7 16`
    do
      echo "runAtacante"
      sshpass -p 'vagrant' ssh root@192.168.0.$i 'bash /home/vagrant/jarbas/Project/jarbas run atacante '$numRodada $tipoDeExperimento &
    done
}

##################################################################
# Objetivo: Inicia monitoramento de dados no servidor atacado.
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runAtacado() {
	echo "Iniciando função em atacado:"
	numRodada="$1"
	tipoDeExperimento="$2"
  time=`date +%s`

  echo "`date +%s` tcpdump" >> jarbas.log
  tcpdump -i eth0 -U -w atacado_$numRodada.cap &

  echo "`date +%s` stress ng" >> jarbas.log
  # stress-ng --cpu 2 --io 2 --vm 4 --vm-bytes 1G --timeout 2s &
  echo "`date +%s` collectl" >> jarbas.log
  # collectl -sscmn -P -f /gpcn/atacado/logs/collectl/"$time"_"$tipoDeExperimento"_"$numRodada" &

  echo "`date +%s` sysbench cpu" >> jarbas.log
  # sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/atacado/logs/sysbench/"$time"_cpu_"$numRodada".log &
  echo "`date +%s` sysbench memory" >> jarbas.log
  # sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/atacado/logs/sysbench/"$time"_memr_"$numRodada".log &
  echo "`date +%s` sysbench memory" >> jarbas.log
  # sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/atacado/logs/sysbench/"$time"_memw_"$numRodada".log &

  echo "`date +%s` sysbench fileio" >> jarbas.log
  # sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare
  echo "`date +%s` sysbench fileio" >> jarbas.log
  # sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/atacado/logs/sysbench/"$time"_disk_"$numRodada".log
  echo "`date +%s` sysbench fileio" >> jarbas.log
  # sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup

  echo "`date +%s` killal collectl" >> jarbas.log
  # killall collectl
	echo "`date +%s` killal tcpdump" >> jarbas.log
  # killall tcpdump
}

##################################################################
# Objetivo: Inicia monitoramento de dados no Hypervisor.
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runXenServer() {
  echo "Iniciando monitoramento XenServer"
  numeroRodada="$1"
  tipoDeExperimento="$2"
  time=`date +%s`

  echo "`date +%s` tcpdump eth1"
  # tcpdump -i eth1 -s 0 -U >> /gpcn/xenserver/log/eth1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  echo "`date +%s` tcpdump vif1"
  # tcpdump -i vif1.0 -s 0 -U >> /gpcn/xenserver/log/vif1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  echo "`date +%s` tcpdump vif2"
  # tcpdump -i vif2.0 -s 0 -U >> /gpcn/xenserver/log/vif2/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  echo "`date +%s` vmstat"
  # vmstat -n 1 >> /gpcn/xenserver/log/vmstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento"

  echo "`date +%s` killall SIGTERM"
  # killall -s SIGTERM tcpdump
  echo "`date +%s` killall vmstat"
  # killall vmstat
  echo "`date +%s` killall xenserver"
  # killall xenserver.sh
}

##################################################################
# Objetivo: Inicia monitoramento no vizinho ao atacado (Monitorado)
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runMonitorado() {
  echo "Iniciando monitoramento"
  numeroRodada="$1"
  tipoDeExperimento="$2"
  COUNT=0
  time=`date +%s`

  echo "`date +%s` tcpdump"
  # tcpdump -i eth1 -U -w client_$numRodada.cap &
  echo "`date +%s` collectl"
  # collectl -sscmn -P -f /gpcn/monitorado/logs/collectl/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  echo "`date +%s` stress"
  # stress-ng --cpu 2 --io 2 --vm 4 --vm-bytes 1G --timeout 840s &

  echo "`date +%s` sysbench"
  # sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/monitorado/logs/sysbench/"$time"_cpu_"$numeroRodada".log &
  echo "`date +%s` sysbench"
  # sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/monitorado/logs/sysbench/"$time"_memr_"$numeroRodada".log &
  echo "`date +%s` sysbench"
  # sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/monitorado/logs/sysbench/"$time"_memw_"$numeroRodada".log &

  echo "`date +%s` sysbench"
  # sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare
  echo "`date +%s` sysbench"
  # sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/monitorado/logs/sysbench/"$time"_disk_"$numeroRodada".log
  echo "`date +%s` sysbench"
  # sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup

  # while [ $COUNT != 1 ]
  # do
  #   # netstat -taupen | grep 80 | wc -l >> /gpcn/monitorado/logs/netstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento"
  #   sleep 1
  #   COUNT=$((COUNT+1))
  # done
  echo "`date +%s` netstat 840"

  echo "`date +%s` killall collectl"
  # killall collectl
  echo "`date +%s` killall netstat"
  # killall netstat
}

##################################################################
# Objetivo: Inicia ataque ao ATACADO
##################################################################
function runAtacante() {
  echo "ethtool" ethtool -s eth0 speed 10 duplex full
  echo "sleep 60"

  #Start t50
  #/root/t50-5.4.1/t50 10.0.24.12 --flood --turbo &
  echo "`date +%s` t50"
  # t50 192.168.0.200 --flood --turbo --dport 80 -S --protocol TCP &

  echo "`date +%s` sleep"
  # sleep 720
  echo "`date +%s` killall"
  # killall t50

  echo '`date +%s` 1' # >> /root/log
  # sleep 5
}

##################################################################
# Objetivo: inicializar os clientes
# Argumentos:
#  $1 -> Numero de Rodadas
#  $2 -> Tipo do experimento
##################################################################
function runCliente() {
  echo "iniciando função nos clientes:"
  COUNT=0
  numRodada="$1"
  tipoDeExperimento="$2"
  time=`date +%s`

  echo "`date +%s` ethtool eth1"
  # ethtool -s eth1 speed 10 duplex full
  echo "`date +%s` ethtool eth2"
  # ethtool -s eth2 speed 10 duplex full

  echo "`date +%s` tcpdump eth1"
  # tcpdump -i eth1 -U -w client_$numRodada.cap &
  echo "`date +%s` tcpdump eth2"
  # tcpdump -i eth2 -U -w client_$numRodada.cap &

  echo "`date +%s` ping 200"
  # ping 192.168.0.200 >> /gpcn/clientes/logs/ping/"$time"_ping_"$numRodada"_"$tipoDeExperimento".srv_01.log &

  echo "`date +%s` ping 201"
  # ping 192.168.10.201 >> /gpcn/clientes/logs/ping/"$time"_ping_"$numRodada"_"$tipoDeExperimento".srv_02.log &

  echo "`date +%s` siege 201"
  # siege -c 100 192.168.10.201 &

  echo "`date +%s` killall SIGINT"
  # killall -s SIGINT ping
  echo "`date +%s` killall SIGINT"
  # killall -s SIGINT siege
  echo "`date +%s` killall SIGINT"
  # killall -s SIGINT tcpdump
}

##################################################################
# Objetivo: Checar se a velocidade da interface foi definida corretamente
# Argumentos:
#   $speed -> Velocidade que a interface deve estar
#   $interface-> Interface que vai checar
##################################################################
function checaInterface() {
  speed=$1
  interface=$2

    comand=`ethtool "$interface" | grep "$speed" | cut -d: -f2 | cut -d/ -f1`
    if [ -z "$comand" ]
      then
          echo "J.A.R.B.A.S LOG: não foi alterada a velocidade das interfaces"
      else
          echo "funcionando"
    fi

}
##############################################################
#
#
#
##############################################################
