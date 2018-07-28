#!/bin/bash
# Autor: Sergei Armando Martao
# Data: 26/09/2017
# Descricao
# 
# Script utilizado para conectar em uma lista de servidores e executar comandos conforme o arquivo que estiver LISTA_COMANDOS
# As principais funcoes sao:
# Testar SSH, valida se o SSH do servidor remoto esta funcionando
# Copiar chave SSH, replica a chave SSH de um servidor para os demais
# Limpar chave SSH, limpa a chave SSH dos servidores
#

function MAIN(){
	CORES
	CONFIGURACOES
	CARREGASERVIDORES
	VALIDASSH
	EXECCOMANDOS	
}

function CONFIGURACOES(){
	#LISTA_SERVIDORES=servidores-linux.csv  # Nao pode conter espaco no arquivo
	LISTA_SERVIDORES=servidores-linux.csv 
	#LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-teste-ssh
	LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-copia-chave
	#LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-limpa-chave
	USER=root
	PORTA[1]=2222 # porta ssh para validar o acesso
	PORTA[2]=22 # Porta ssh para validar o acesso
	TIME=10 # Tempo para executar o timeout no comando
	ARQLOG="conecta_servidores_`date "+%y-%m-%d-%H-%M"`.log"
} 

function CARREGASERVIDORES(){
	a=1
	for i in `cat $LISTA_SERVIDORES | grep -i ativo | grep -viE "windows*" | cut -d, -f1,2,3,4`
	do
		CI[$a]=`echo $i | cut -d, -f1`
		STATUS[$a]=`echo $i | cut -d, -f2`
		IP[$a]=`echo $i | cut -d, -f3`
		SO[$a]=`echo $i | cut -d, -f4`
		let a=$a+1
	done
}

function VALIDASSH(){
	for((s=1;s<=${#IP[@]};s++));
	do
		PORTASSH[$s]=0 # Setando que o padrao e a porta estar fechado
		STATUSSH[$s]=2 # E o status de igorado
		for((a=1;a<=${#PORTA[@]};a++)); # Validando todas as portas ssh disponiveis
		do
			STATUSSSH=`timeout $TIME nmap ${IP[$s]} -n -sT -Pn -p${PORTA[$a]} | grep -i ${PORTA[$a]} | grep -i tcp | cut -d' ' -f2`
			if [ $STATUSSSH == "open" ];then # caso a prota esteja aberta no servidor
				PORTASSH[$s]=${PORTA[$a]} 
				STATUSSH[$s]=1
			fi
		done
	done
}

function EXECCOMANDOS(){
	a=`wc -l $LISTA_COMANDOS | cut -d' ' -f 1` # Coletando o numero de comandos para executar
	for((b=1;b<=a;b++));
	do
		COMANDO=`cat $LISTA_COMANDOS | head -n $b $LISTA_COMANDOS | tail -n 1`
		for((s=1;s<=${#IP[@]};s++));
       		do
			if [ ${PORTASSH[$s]} -ne 0 ];then
				#timeout $TIME ssh -p ${PORTASSH[$s]} $USER@${IP[$s]} $COMANDO > /dev/null 2>&1
				#timeout $TIME `$COMANDO` > /dev/null 2>&1
				#source $LISTA_COMANDOS 
				#. $LISTA_COMANDOS
				eval $COMANDO > /dev/null 2>&1
				T=$?; TESTET
			else
				T=2; TESTET
			fi
		done
	done
}

function TESTET(){ 
	case $T in
		"0")
			echo -ne "[$CVD OK $CF]\t\t " | tee -a $ARQLOG
			;;
		"2")
 			echo -ne "[$CAM IGNORADO $CF]\t " | tee -a $ARQLOG
			;;
		*)
			echo -ne "[$CVE FALHA $CF]\t " | tee -a $ARQLOG
		 ;; 
	esac
	echo -en "CI:${CI[$s]}" | tee -a $ARQLOG
	echo -en " C:" | tee -a $ARQLOG
	eval "echo -e $COMANDO" | tee -a $ARQLOG
}

function CORES(){
        CVE='\e[1;31m' # Red Bold
        CVD='\e[1;32m' # Green Bold
        CAM='\e[1;33m' # Yellow Bold
         CF='\e[0m'    # Tag end
}

MAIN
exit;
