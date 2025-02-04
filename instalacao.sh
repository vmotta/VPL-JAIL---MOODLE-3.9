#!/bin/bash

# Script de instalação do VPL Jail System 4.0.3

# Definir variáveis
VPL_VERSION="4.0.3"
VPL_DIR="/home/administrador/vpl-jail-system-$VPL_VERSION"
VPL_URL="https://vpl.dis.ulpgc.es/releases/vpl-jail-system-$VPL_VERSION.tar.gz"
CERT_DIR="/etc/vpl/ssl"
CONFIG_FILE="/etc/vpl/vpl-jail-system.conf"
FOLDER_CERT="/home/administrador"

# Função para verificar e instalar dependências
install_dependencies() {
    echo "Instalando dependências..."
    sudo apt-get update
    sudo apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libjsoncpp-dev
}

# Função para baixar e extrair o VPL
download_and_extract_vpl() {
    echo "Baixando e extraindo o VPL Jail System $VPL_VERSION..."
    wget $VPL_URL -O /tmp/vpl-jail-system-$VPL_VERSION.tar.gz
    tar -xzf /tmp/vpl-jail-system-$VPL_VERSION.tar.gz -C /home/administrador
}

# Função para compilar e instalar o VPL
compile_and_install_vpl() {
    echo "Compilando e instalando o VPL Jail System $VPL_VERSION..."
    cd $VPL_DIR
    ./install-vpl-sh full
}

# Função para configurar o VPL
configure_vpl() {
    echo "Configurando o VPL Jail System..."
    sudo mkdir -p $CERT_DIR

    # Copiar certificados para o diretório correto (ajustar os caminhos conforme necessário)
    sudo cp $FOLDER_CERT/cefor.cefetes.br.cer $CERT_DIR/fullchain.pem
    sudo cp $FOLDER_CERT/cefor.cefetes.br.key $CERT_DIR/
    sudo cp $FOLDER_CERT/cefor.cefetes.br-2023-2024.pem $CERT_DIR/
    sudo cp $FOLDER_CERT/intermediate.pem $CERT_DIR/

    # Ajustar permissões dos arquivos de certificados
    sudo chown -R administrador:administrador $CERT_DIR
    sudo chmod 600 $CERT_DIR/*

    # Configurar o arquivo de configuração do VPL
    sudo bash -c "cat > $CONFIG_FILE" <<EOL
# CONFIGURATION FILE OF vpl-jail-system
#
# Format VAR=VALUE #no space before and after "="
# To apply changes you must restart the service using
# "systemctl restart vpl-jail-system" or "service vpl-jail-system restart"

#JAILPATH set the jail path
JAILPATH=/jail

#MIN_PRISONER_UGID set start first user id for prisoners
MIN_PRISONER_UGID=10000

#MAX_PRISONER_UGID set the last user id for prisoners
MAX_PRISONER_UGID=12000

#MAXTIME set the maximum time for a request in seconds
MAXTIME=1800

#Maximum file size in bytes
#MAXFILESIZE=64000000

#Maximum memory size in bytes
#MAXMEMORY=2000000

#Maximum number of process
#MAXPROCESSES=500

#Path to control directory. the system save here information of request in progress
#CONTROLPATH="/var/vpl-jail-system"

#Limit the servers from we accept a request
#IP or net (type A, B and C) separate with spaces
#Format IP: full dot notation. Example: 128.122.11.22
#Format net: dot notation ending with dot. Example: 10.1.
#TASK_ONLY_FROM=10.10.3.

#To serve only to one interface of your system
#INTERFACE=128.1.1.1

#Socket port number to listen for connections (http: and ws:)
#default 80. 0 removes
PORT=80

#Socket port number to listen for secure connections (https: and wss:)
#default 443
SECURE_PORT=443

#URL path for task request
#act as a password, if no matches with the path of the request then it's rejected
URLPATH=/

#FIREWALL=0|1|2|3|4
#0: No firewall
#1: VPL service+DNS+internet access
#2: VPL service+DNS+Limit Internet to port 80 (super user unlimited)
#3: VPL service+No external access (super user unlimited)
#4: VPL service+No external access
#Note: In level 4 stop vpl-jail-system service to update/upgrade the system
#Note: Don not use in CentOS
#default level 0
FIREWALL=0

#ENVPATH is environment PATH var set when running tasks
#IMPORTANT: If you are using RedHat or derived OSes you must set this parameter to the
#PATH environment variable of common users (not root) example
#ENVPATH=/usr/bin:/bin

#LOGLEVEL is the log level of the program
#From 0 to 8. 0 minimum log to 8 maximum log and don't removes prisoners home dir.
#IMPORTANT: Do not use high loglevel in production servers, you will get pour performance
#default level 3
LOGLEVEL=3

#FAIL2BAN is a numeric parameter to ban IPs based on the number of failed requests
# 0: disable banning
# The banning criteria is the number of fail > 20 * FAIL2BAN and more failed requests that successful requests.
# The fail counter are reset every five minutes. The banning last five minutes.
#default 0
#FAIL2BAN=0

#USETMPFS This switch allows the use of the tmpfs for "/home" and the "/dev/shm" directories
#Changes this switch to "false" can degrade the performance of the jail system .
#To deactivate set USETMPFS=false
#USETMPFS=true

#HOMESIZE The limits of modifications of the "duplicate" directory the default value is 30% of the system memory
# or 2Gb if USETMPFS=false
#HOMESIZE=30%
#HOMESIZE=2G

#SHMSIZE The size of the "/dev/shm" directory he default value is 30% of the system memory
#This option is applicable if using tmpfs file system for the "/dev/shm" directory
#SHMSIZE=30%

#ALLOWSUID This switch allows the execution of programs with a suid bit inside the jail.
#This may be a security threat, use at your own risk. To activate set ALLOWSUID=true
#ALLOWSUID=false

#SSL_CIPHER_LIST This parameters specifies ciphering optiosn for SSL.
#In case of wanting to have Forward Secrecy the option must be: ECDHE
#SSL_CIPHER_LIST=

#SSL_CIPHER_SUITES This parameters configure the available TLSv1.3 ciphersuites.
#The parameter is a colon (":") separated TLSv1.3 ciphersuite names in order of preference.
#SSL_CIPHER_SUITES=

#HSTS_MAX_AGE HTTP Strict-Transport-Security. Set max-age of the Strict-Transport-Security header.
#Must be a nonnegative number. Must be combined with PORT=0. Default none.
#HSTS_MAX_AGE=31536000

#SSL_CERT_FILE Indicates the path to the server's certificate
# If your Certification Authority is not a root authority
# you may need to add the chain of certificates of the intermediate CAs to this file.
SSL_CERT_FILE=$CERT_DIR/fullchain.pem

#SSL_KEY_FILE Indicates the path to the server's private key
SSL_KEY_FILE=$CERT_DIR/cefor.cefetes.br.key

#SSL_CA_FILE Indicates the path to the chain of certificates
SSL_CA_FILE=$CERT_DIR/intermediate.pem
EOL
}

# Função para iniciar o serviço VPL Jail System
start_vpl_service() {
    echo "Iniciando o serviço VPL Jail System..."
    sudo systemctl daemon-reload
    sudo systemctl enable vpl-jail-system
    sudo systemctl start vpl-jail-system
}

# Executar as funções
install_dependencies
download_and_extract_vpl
compile_and_install_vpl
configure_vpl
start_vpl_service

echo "Instalação e configuração do VPL Jail System $VPL_VERSION concluídas!"
