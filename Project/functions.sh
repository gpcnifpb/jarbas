#!/bin/bash

##################################################################
# Objetivo: Executa o experimento por completo.
# Argumentos:
#   $1 -> Numero de rodadas
#   $2 -> Exit status (optional)
##################################################################
function run() {
  if [ $1 -gt 1 ]; then
    printf "\n\tExecutando experimento com $1 rodadas.\n\n"
  else
    printf "\n\tExecutando experimento com $1 rodada.\n\n"
  fi
  numRodadas="$1"
  durRodada="60" # Duração em segundos

  for r in `seq 1 $numRodadas`
  do
    printf "\n##################################################################\n"
    printf "\n######################|      RODADA $r      |######################\n"
    printf "\n##################################################################\n\n"

  runRodada $r $durRodada "SemAtaque"
    retorno=$?
    if [ "$retorno" == 0 ]; then
    printf "\n###########| RODADA SEM ATAQUE CONCLUÍDA COM SUCESSO! |###########\n\n"
    else
  printf "\n###################| RODADA SEM ATAQUE SOFREU UM ERRO |###################\n"
    printf "\n################| [ERRO] $retorno |################\n"
    fi

    #runRodada $r $durRodada "ComAtaque"
    #if [ "$retorno" == 0 ]; then
    #  printf "\n###########| RODADA COM ATAQUE CONCLUÍDA COM SUCESSO! |###########\n\n"
    #else
    #  printf "\n###################| RODADA COM ATAQUE SOFREU UM ERRO |###################\n"
    #  printf "\n################| [ERRO] $retorno |################\n"
    #fi

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
function runRodada() {
  numRodada="$1"
  durRodada="$2"
  tipoDeExperimento="$3"

  #printf "\tIniciando Xenserver...\n"
  #sshpass -p 'vagrant' ssh root@10.0.4.186 'bash /root/gpcn/xenserver/scripts/jarbas/Project/jarbas run xenserver' $numRodada  $tipoDeExperimento $durRodada &

  #printf "\tIniciando atacado...\n"
  #sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas/Project/jarbas run atacado '$numRodada  $tipoDeExperimento $durRodada &
  # jarbas run atacado $numRodada  $tipoDeExperimento $durRodada &

  #printf "\tIniciando monitorado...\n"
  #sshpass -p 'vagrant' ssh root@192.168.10.201 'bash /gpcn/monitorado/scripts/jarbas/Project/jarbas run monitorado' $numRodada  $tipoDeExperimento $durRodada &
  # jarbas run monitorado $numRodada  $tipoDeExperimento $durRodada &

  for c in `seq 1 6`
  do
  printf "\tIniciando cliente $c...\n"
  sshpass -p 'vagrant' ssh root@192.168.0.$c 'bash /home/vagrant/jarbas/Project/jarbas run cliente ' $numRodada  $tipoDeExperimento $durRodada &
   jarbas run cliente $numRodada  $tipoDeExperimento $durRodada &
  done

  #if [ "$tipoDeExperimento" == "ComAtaque" ]; then
  #for a in `seq 7 16`
  #do
  #  printf "\tIniciando atacante $a...\n"
  #  sshpass -p 'vagrant' ssh root@192.168.0.$a 'bash /home/vagrant/jarbas/Project/jarbas run atacante ' $numRodada $tipoDeExperimento $durRodada &
  # jarbas run atacante $numRodada $durRodada $tipoDeExperimento &
  #done
  #fi

  printf "\n\tTempo de execução estimado é de $durRodada segundos.\n\n"
  c="1"
  while [ $c -le $durRodada ]
  do
    sleep 1
    printf "."
    (( c++ ))
  done
  printf "\n"
}

##################################################################
# Objetivo: Inicia monitoramento de dados no servidor atacado.
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runAtacado() {
  numRodada="$1"
  tipoDeExperimento="$2"
  durRodada="$3"
  time=`date +%s`

  tcpdump -i eth0 -U -w atacado_$numRodada.cap &
  echo "`date +%s` $tipoDeExperimento tcpdump" >> jarbas_local.log

  stress-ng --cpu 2 --io 2 --vm 4 --vm-bytes 1G --timeout "$durRodada"s &
  echo "`date +%s` $tipoDeExperimento stress ng" >> jarbas_local.log
  collectl -sscmn -P -f /gpcn/atacado/logs/collectl/"$time"_"$tipoDeExperimento"_"$numRodada" &
  echo "`date +%s` $tipoDeExperimento collectl" >> jarbas_local.log

  sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/atacado/logs/sysbench/"$time"_cpu_"$numRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench cpu" >> jarbas_local.log
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/atacado/logs/sysbench/"$time"_memr_"$numRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench memory" >> jarbas_local.log
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/atacado/logs/sysbench/"$time"_memw_"$numRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench memory" >> jarbas_local.log

  sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare
  echo "`date +%s` $tipoDeExperimento sysbench fileio" >> jarbas_local.log
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/atacado/logs/sysbench/"$time"_disk_"$numRodada".log
  echo "`date +%s` $tipoDeExperimento sysbench fileio" >> jarbas_local.log
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup
  echo "`date +%s` $tipoDeExperimento sysbench fileio" >> jarbas_local.log

  c="1"
  while [ $c -le $durRodada ]
  do
    sleep 1
    (( c++ ))
  done

  killall collectl
   echo "`date +%s` $tipoDeExperimento killal collectl" >> jarbas_local.log
  killall tcpdump
  echo "`date +%s` $tipoDeExperimento killal tcpdump" >> jarbas_local.log

}

##################################################################
# Objetivo: Inicia monitoramento de dados no Hypervisor.
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runXenServer() {
  numeroRodada="$1"
  tipoDeExperimento="$2"
  durRodada="$3"
  time=`date +%s`
  # TODO mudar diretórios das interfaces vif
  tcpdump -i eth1 -s 0 -U >> /root/gpcn/xenserver/log/eth1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log &
  echo "`date +%s` $tipoDeExperimento tcpdump eth1" >> jarbas_local.log
  tcpdump -i vif6.1 -s 0 -U >> /root/gpcn/xenserver/log/vif1/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log &
  echo "`date +%s` $tipoDeExperimento tcpdump vif6.1" >> jarbas_local.log
  tcpdump -i vif9.1 -s 0 -U >> /root/gpcn/xenserver/log/vif2/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log &
  echo "`date +%s` $tipoDeExperimento tcpdump vif8.1" >> jarbas_local.log
  vmstat -n 1 >> /root/gpcn/xenserver/log/vmstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log
  echo "`date +%s` $tipoDeExperimento vmstat" >> jarbas_local.log

  c="1"
  while [ $c -le $durRodada ]
  do
    sleep 1
    (( c++ ))
  done

  killall -s SIGTERM tcpdump
  echo "`date +%s` $tipoDeExperimento killall SIGTERM" >> jarbas_local.log
  killall vmstat
  echo "`date +%s` $tipoDeExperimento killall vmstat" >> jarbas_local.log
  killall xenserver.sh
  echo "`date +%s` $tipoDeExperimento killall xenserver" >> jarbas_local.log
}

##################################################################
# Objetivo: Inicia monitoramento no vizinho ao atacado (Monitorado)
# Argumentos:
#   $1 -> Numero da Rodada
#   $2 -> Tipo do experimento
##################################################################
function runMonitorado() {
  numeroRodada="$1"
  tipoDeExperimento="$2"
  durRodada="$3"
  COUNT=0
  time=`date +%s`

  tcpdump -i eth1 -U -w client_$numRodada.cap &
  echo "`date +%s` $tipoDeExperimento tcpdump" >> jarbas_local.log
  collectl -sscmn -P -f /gpcn/monitorado/logs/collectl/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log &
  echo "`date +%s` $tipoDeExperimento collectl" >> jarbas_local.log
  stress-ng --cpu 2 --io 2 --vm 4 --vm-bytes 1G --timeout 60s &
  echo "`date +%s` $tipoDeExperimento stress" >> jarbas_local.log

  sysbench --test=cpu --cpu-max-prime=200000 --max-time=120s --num-threads=4 run >> /gpcn/monitorado/logs/sysbench/"$time"_cpu_"$numeroRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=read run >> /gpcn/monitorado/logs/sysbench/"$time"_memr_"$numeroRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log
  sysbench --test=memory --memory-block-size=1K --memory-total-size=50G --memory-oper=write run >> /gpcn/monitorado/logs/sysbench/"$time"_memw_"$numeroRodada".log &
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log

  sysbench --test=fileio --num-threads=32 --file-total-size=4G --file-test-mode=rndrw prepare
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw run >> /gpcn/monitorado/logs/sysbench/"$time"_disk_"$numeroRodada".log
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log
  sysbench --test=fileio --num-threads=16 --file-total-size=2G --file-test-mode=rndrw cleanup
  echo "`date +%s` $tipoDeExperimento sysbench" >> jarbas_local.log

  c="1"
  while [ $c -le $durRodada ]
  do
    netstat -taupen | grep 80 | wc -l >> /gpcn/monitorado/logs/netstat/"$time"_rodada_"$numeroRodada"_"$tipoDeExperimento".log
    sleep 1
    (( c++ ))
  done

  echo "`date +%s` $tipoDeExperimento netstat 840" >> jarbas_local.log
  killall collectl
  echo "`date +%s` $tipoDeExperimento killall collectl" >> jarbas_local.log
  # killall netstat
  # echo "`date +%s` $tipoDeExperimento killall netstat" >> jarbas_local.log
}

##################################################################
# Objetivo: Inicia ataque ao ATACADO
##################################################################
function runAtacante() {
  numRodada="$1"
  tipoDeExperimento="$2"
  durRodada="$3"

  ethtool -s eth0 speed 10 duplex full
  echo "`date +%s` $tipoDeExperimento ethtool eth0" >> jarbas_local.log
  #echo "sleep 60"

  #Start t50
  #/root/t50-5.4.1/t50 10.0.24.12 --flood --turbo &
  t50 192.168.0.200 --flood --turbo --dport 80 -S --protocol TCP &
  echo "`date +%s` $tipoDeExperimento t50" >> jarbas_local.log

  # TODO Tempo de execução do experimento deve ser passaado como parametro
  sleep $durRodada
  echo "`date +%s` $tipoDeExperimento sleep" >> jarbas_local.log

  c="1"
  while [ $c -le $durRodada ]
  do
    sleep 1
    (( c++ ))
  done

  killall t50 > /dev/null
  echo "`date +%s` $tipoDeExperimento killall" >> jarbas_local.log
}

##################################################################
# Objetivo: inicializar os clientes
# Argumentos:
#  $1 -> Numero de Rodadas
#  $2 -> Tipo do experimento
##################################################################
function runCliente() {
  COUNT=0
  numRodada="$1"
  tipoDeExperimento="$2"
  time=`date +%s`

  ethtool -s eth1 speed 10 duplex full
  echo "`date +%s` $tipoDeExperimento ethtool eth1" >> jarbas_local.log
  ethtool -s eth2 speed 10 duplex full
  echo "`date +%s` $tipoDeExperimento ethtool eth2" >> jarbas_local.log

  tcpdump -i eth1 -U -w client_eth1_$numRodada.cap &
  echo "`date +%s` $tipoDeExperimento tcpdump eth1" >> jarbas_local.log
  tcpdump -i eth2 -U -w client_eth2_$numRodada.cap &
  echo "`date +%s` $tipoDeExperimento tcpdump eth2" >> jarbas_local.log

  ping 192.168.0.200 >> /gpcn/clientes/logs/ping/"$time"_ping_"$numRodada"_"$tipoDeExperimento".srv_01.log &
  echo "`date +%s` $tipoDeExperimento ping 200" >> jarbas_local.log

  ping 192.168.10.201 >> /gpcn/clientes/logs/ping/"$time"_ping_"$numRodada"_"$tipoDeExperimento".srv_02.log &
  echo "`date +%s` $tipoDeExperimento ping 201" >> jarbas_local.log

  siege -c 100 192.168.10.201 &
  echo "`date +%s` $tipoDeExperimento siege 201" >> jarbas_local.log

  c="1"
  while [ $c -le $durRodada ]
  do
    sleep 1
    (( c++ ))
  done

  killall -s SIGINT ping
  echo "`date +%s` $tipoDeExperimento killall ping" >> jarbas_local.log
  killall -s SIGINT siege
  echo "`date +%s` $tipoDeExperimento killall siege" >> jarbas_local.log
  killall -s SIGINT tcpdump
  echo "`date +%s` $tipoDeExperimento killall tcpdump" >> jarbas_local.log
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
