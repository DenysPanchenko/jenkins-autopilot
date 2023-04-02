#!/bin/bash

# Path variables
JENKINS_HOME=./home
JENKINS_CERTS=./certs

# Docker variables
JENKINS_IMAGE=myjenkins-blueocean:lts
JENKINS_NETWORK=jenkins
JENKINS_MASTER=jenkins
JENKINS_DIND=jenkins-docker

# HTTPS variables
JENKINS_HTTPS_PORT=8443
JENKINS_KEYSTORE=jenkins-keystore.jks
KEYSTORE_PASS=$(openssl rand -base64 32) # Random 32 symbols length pass

# Clean up function
function clean_up() {
    echo_bold_green "Remove Jenkins container"
    sudo docker remove $JENKINS_MASTER

    echo_bold_green "Remove Jenkins docker container"
    sudo docker remove $JENKINS_DIND

    echo_bold_green "Removing 'jenkins' network from Docker"
    sudo docker network rm $JENKINS_NETWORK

    echo_bold_green "Removing Jenkins container"
    sudo docker rmi $JENKINS_IMAGE

    echo_bold_green "Removing Jenkins home folder"
    rm -rf $JENKINS_HOME

    echo_bold_green "Removing cerst folder"
    rm -rf $JENKINS_CERTS

    echo_bold_green "Removing keystore file"
    rm $JENKINS_KEYSTORE
}

function create_jenkins() {
    echo_section "Spinning up Jenkins in Docker"

    if ! docker -v &> /dev/null
    then
        echo_bold_red "Docker is not installed. Please install docker first. More info: https://docs.docker.com/engine/install/centos/"
        return 1
    else
        echo "Docker version found: $(docker -v)" 
    fi

    echo_bold_blue "Creating docker network: '$JENKINS_NETWORK'"
    sudo docker network create $JENKINS_NETWORK

    echo_bold_blue "Building Jenkins LTS docker image with installed docker with tag $JENKINS_IMAGE"
    sudo docker build -t $JENKINS_IMAGE .

    echo_bold_blue "Creating folder for Jenkins home: $JENKINS_HOME"
    mkdir $JENKINS_HOME

    echo_bold_blue "Creating folder for dind certs: $JENKINS_CERTS"
    mkdir $JENKINS_CERTS

    echo_bold_blue "Generating keystore file for HTTPS connection"
    keytool -genkey -keyalg RSA -alias selfsigned -keystore $JENKINS_KEYSTORE -storepass $KEYSTORE_PASS -keysize 2048

    echo_bold_blue "Copying keystore file to Jenkins home"
    cp $JENKINS_KEYSTORE $JENKINS_HOME

    echo_section "Running DinD container"
    sudo docker run \
    --name $JENKINS_DIND \
    --restart=on-failure \
    --detach \
    --privileged \
    --network $JENKINS_NETWORK \
    --network-alias docker \
    --volume $JENKINS_CERTS:/certs/client \
    --volume $JENKINS_HOME:/var/jenkins_home \
    --publish 2376:2376 \
    docker:dind --storage-driver overlay2

    echo_section "Running Jenkins container"
    sudo docker run \
    --name $JENKINS_MASTER \
    --restart=on-failure \
    --detach \
    --network $JENKINS_NETWORK \
    --env DOCKER_HOST=tcp://docker:2376 \
    --env DOCKER_CERT_PATH=/certs \
    --env DOCKER_TLS_VERIFY=1 \
    --volume $JENKINS_HOME:/var/jenkins_home \
    --volume $JENKINS_CERTS:/certs:ro \
    --publish 5000:5000 \
    --publish $JENKINS_HTTPS_PORT:$JENKINS_HTTPS_PORT \
    $JENKINS_IMAGE \
    --httpPort=-1 \
    --httpsPort=$JENKINS_HTTPS_PORT \
    --httpsKeyStore=/var/jenkins_home/$JENKINS_KEYSTORE \
    --httpsKeyStorePassword=$KEYSTORE_PASS

    echo_bold_green "Jenkins successfully deployed! You can access it via HTTPS on port: $JENKINS_HTTPS_PORT"
    echo ""
    echo "Run script with parameter --get-admin-pass to get admin pass"
}

function start_jenkins() {
    echo_bold_green  "Starting Jenkins docker"
    sudo docker start $JENKINS_DIND

    echo_bold_green "Starting Jenkins master"
    sudo docker start $JENKINS_MASTER
}

function echo_section() {
    echo ""
    echo_bold_green "  $1"
    echo ""
}

function echo_bold_green() {
    echo -e "\e[32m\e[1m"$1"\e[0m"
}

function echo_bold_red() {
    echo -e "\e[31m\e[1m"$1"\e[0m"
}

function echo_bold_blue() {
    echo -e "\e[34m\e[1m"$1"\e[0m"
}

function stop_jenkins() {
    echo_bold_green "Stopping running Jenkins master"
    sudo docker stop $JENKINS_MASTER

    echo_bold_green "Stopping running Jenkins docker"
    sudo docker stop $JENKINS_DIND
}

function get_admin_pass() {
    if [ -f $JENKINS_HOME/secrets/initialAdminPassword ]; then
        echo ""
        echo "Use this password for first login in Jenkins: $(cat $JENKINS_HOME/secrets/initialAdminPassword)"
        echo ""
    else
        echo ""
        echo "Jenkins is not yet initialized. Please wait a few minutes and re-run the command"
        echo ""
    fi
}

function show_usage() {
    echo ""
    echo "Usage: $0 [--clean | --new | --start | --stop | --restart | --get-admin-pass]"
    echo ""
}

# Main script
if [[ $# -ne 1 ]]; then
    show_usage
    exit 1
fi

case "$1" in
    --clean)
        stop_jenkins
        clean_up
        ;;
    --new)
        create_jenkins
        ;;
    --start)
        start_jenkins
        ;;
    --stop)
        stop_jenkins
        ;;
    --restart)
        stop_jenkins
        start_jenkins
        ;;
    --get-admin-pass)
        get_admin_pass
        ;;
    *)
        echo ""
        echo_bold_red "Invalid argument: $1"
        show_usage
        exit 1
        ;;
esac

exit 0
