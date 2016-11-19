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
#   $1 -> Numero da Rodada
##################################################################
function runSemAtaque() {
	numRodadas="$1"
	tipoDeExperimento="SemAtaque"

  echo "Executando sem ataque na rodada $1"
	echo "Executando função em atacado: "
	sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas run atacado '$numRodadas $tipoDeExperimento
}

##################################################################
# Objetivo: Executa o experimento com ataque (Clientes e atacantes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runComAtaque() {
  	numRodada="$1"
    tipoDeExperimento="$2"
  	echo "Executando com ataque na rodada $1"

    sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas run atacado '$numRodadas $tipoDeExperimento
    sshpass -p 'vagrant' ssh root@192.168.0.201 'bash /gpcn/monitorado/scripts/jarbas run monitorado '$numRodadas $tipoDeExperimento

    for i in `seq 1 6`
    do
      sshpass -p 'vagrant' ssh root@192.168.0.$i 'bash /gpcn/clientes/scripts/jarbas run cliente '$numRodada $tipoDeExperimento &
    done

    for i in `seq 7 16`
    do
      sshpass -p 'vagrant' ssh root@192.168.0.$i 'bash /gpcn/atacantes/scripts/jarbas run atacante '$numRodada $tipoDeExperimento &
    done
}

##################################################################
# Objetivo: Inicia monitoramento de dados no servidor atacado.
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function funcAtacado() {
	echo "Iniciando função em atacado:"
	COUNT=0
	numRodadas="$1"
	tipoDeExperimento="$2"

	collectl -sscmn -P -f /gpcn/atacado/logs/collectl/$tipoDeExperimento_$numRodadas &

	while [ $COUNT != 60 ]
	do
		netstat -taupen | grep 80 | wc -l >> /gpcn/atacado/logs/netstat/socket_$tipoDeExperimento_$numRodadas.log
		sleep 1
		COUNT=$((COUNT+1))
	done

	killall collectl
	killall jarbas
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

  tcpdump -i eth1 -s 0 -U >> /gpcn/xenserver/log/eth1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  tcpdump -i vif1.0 -s 0 -U >> /gpcn/xenserver/log/vif1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  tcpdump -i vif2.0 -s 0 -U >> /gpcn/xenserver/log/vif2/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &
  vmstat -n 1 >> /gpcn/xenserver/log/vmstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento"

  killall -s SIGTERM tcpdump
  killall vmstat
  killall xenserver.sh
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

  collectl -sscmn -P -f /gpcn/monitorado/logs/collectl/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento" &

  # TODO Executar simultaneamente os comandos abaixo.

  sleep 70
  sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare
  sleep 10
  sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/monitorado/logs/sysbench/cpu_$numeroRodada.log
  sleep 10
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/monitorado/logs/sysbench/disk_$numeroRodada.log
  sleep 10
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/monitorado/logs/sysbench/memr_$numeroRodada.log
  sleep 10
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/monitorado/logs/sysbench/memw_$numeroRodada.log
  sleep 10
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup

  while [ $COUNT != 840 ]
  do
    netstat -taupen | grep 80 | wc -l >> /gpcn/monitorado/logs/netstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento"
    sleep 1
    COUNT=$((COUNT+1))
  done

  killall collectl

}
##################################################################
# Objetivo: Inicia ataque ao ATACADO
##################################################################
function runAtacante() {
  ethtool -s eth0 speed 10 duplex full
  sleep 60

  #Start t50
  #/root/t50-5.4.1/t50 10.0.24.12 --flood --turbo &
  t50 192.168.0.200 --flood --turbo --dport 80 -S --protocol TCP &

  sleep 720
  killall t50

  echo '1' >> /root/log
  sleep 5
}
