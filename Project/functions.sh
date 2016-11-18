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

  for i in `seq 1 $numRodadas`
  do
    echo "Rodada: $i"
    runSemAtaque $i
    runComAtaque $i
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
#   $1 -> Numero de Rodadas
##################################################################
function runSemAtaque() {
	numRodadas="$1"
	tipoDeExperimento="SemAtaque"

  	echo "Executando sem ataque na rodada $1"
	echo "Executando função em atacado: "
	sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas run atacado '$numRodadas $tipoDeExperimento
  for i in `seq 1 6`
  do
    sshpass -p 'vagrant' ssh root@192.168.0.$i '/gpcn/clientes/scripts/jarbas run cliente '$numRodadas $tipoDeExperimento &
    echo "OUCH $i clients"
  done
  echo 'OUCH Esperando 1080 segundos'
  sleep 1080
}

##################################################################
# Objetivo: Executa o experimento com ataque (Clientes e atacantes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runComAtaque() {
  	numRodadas=$1
    tipoDeExperimento="ComAtaque"
  	echo "Executando com ataque na rodada $1"
}

##################################################################
# Objetivo: Executa o experimento sem ataque (Só clientes)
# Argumentos:
#   $1 -> Numero de Rodadas
#   $2 -> Tipo do experimento
##################################################################
function funcAtacado() {
	echo "Iniciando função em atacado:"
	COUNT=0
	numRodadas="$1"
	tipoDeExperimento="$2"

	collectl -sscmn -P -f /gpcn/atacado/logs/collectl/$tipoDeExperimento_$numRodadas &
  sshpass -p 'vagrant' ssh root@192.168.0.200 'stress-ng --cpu 2 --io 2 --vm 4 --vm-bytes 1G --timeout 840s' &
  sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare &
  sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/monitorado/logs/sysbench/cpu_$numRodadas.log &
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/monitorado/logs/sysbench/disk_$numRodadas.log &
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/monitorado/logs/sysbench/memr_$numRodadas.log &
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/monitorado/logs/sysbench/memw_$numRodadas.log &
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup &


	killall collectl
	killall jarbas
}
##################################################################
# Objetivo: inicializar os clientes
# Argumentos:
#   $numCliente->
#
##################################################################
function funcCliente(){
  echo "iniciando função nos clientes:"
  COUNT=0
  numClient="$1"

  ethtool -s eth1 speed 10 duplex full
  ethtool -s eth2 speed 10 duplex full

  tcpdump -i eth0 -U -w client_$numClient.cap &
#Ping Atacado
  ping 192.168.0.200 >> /gpcn/clientes/logs/ping/ping_$numClient.clt_01_srv_01.txt &
#Ping Nao-Atacado
  ping 192.168.10.201 >> /gpcn/clientes/logs/ping/ping_$numClient.clt_01_srv_02.txt &
#Start Siege
  siege -c 100 192.168.10.201 &
#Finalizando
  killall -s SIGINT ping
  killall -s SIGINT siege
  killall -s SIGINT tcpdump

##################################################################
# Objetivo: Checar se a velocidade da interface foi definida corretamente
# Argumentos:
#   $Inter-> Interface que vai checar
#   $Speed -> Velocidade que a interface deve estar
##################################################################
function checaInterface(){

    comand=`ethtool eth0 | grep "10Mb" | cut -d: -f2 | cut -d/ -f1`
    if [ -z "$comand" ]
      then
          echo "J.A.R.B.A.S LOG: não foi alterada a velocidade das interfaces"
      else
          echo "funcionando"
    fi

}
