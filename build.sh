#!/bin/bash

set -e

NODE=12.16.2
YARN=1.22.4
NGCLI=9.1.6

# BASE is code base
cd $(dirname $0)
export BASE=$(pwd)

if [ -f ".env" ]; then
    source .env
fi

# DOCKER_REPO=${DOCKER_REPO}
DOCKER_IMAGE=${DOCKER_IMAGE:-"angular-docker-builder"}

# Set docker image tag
#   1. as envvar
#   2. set in .env
#   3. via -t TAG (later)
TAG=${TAG:-latest}

# Needs to be same as inside Dockerfile
WORKDIR=/workdir

COMPILE=
PUSH=
LOGIN=
SHELL=
RUN=
OK=

set -o nounset

# quick and dirty test to check vars are set
echo $DOCKER_REPO > /dev/null

DOCKER_IMAGE_TAGGED="$DOCKER_REPO/$DOCKER_IMAGE:$TAG"

function login() {
    echo $DOCKER_PASSWORD | docker login --username $DOCKER_USER --password-stdin
}

function usage() {
    echo "Usage: -c[ompile] -p[ush] -l[ogin] -t TAG -s[hell] -x <commands>"
    exit 1
}

function compile() {
    set -x
    echo "Compiling docker"
    docker build . --rm \
        --build-arg node_version=${NODE} \
        --build-arg yarn_version=${YARN} \
        --build-arg ng_version=${NGCLI} \
        -t $DOCKER_IMAGE:latest \
        -f Dockerfile

    set +x
    docker tag $DOCKER_IMAGE:latest $DOCKER_IMAGE_TAGGED
    if [ $TAG != latest ]; then
        docker tag $DOCKER_IMAGE:latest $DOCKER_IMAGE:$TAG
    fi
    if [ -z "$PUSH" ]; then
        echo "Use -p to publish"
        exit 0
    fi
}

function push() {
    login

    docker tag $DOCKER_IMAGE:latest "$DOCKER_REPO/$DOCKER_IMAGE:latest"
    docker push $DOCKER_REPO/$DOCKER_IMAGE:latest
    if [ $TAG != latest ]; then
        docker push $DOCKER_IMAGE_TAGGED
    fi
    exit 0
}

OPTS=":cplsxt:"
while getopts $OPTS opt; do
    case $opt in
        t)
            # Use alternative image in addition to latest of "latest"
            TAG=$OPTARG
            DOCKER_IMAGE_TAGGED="$DOCKER_REPO/$DOCKER_IMAGE:$TAG"
            ;;
        c)
            # Compile docker image
            COMPILE=1
            OK=1
            ;;
        p)
            PUSH=1
            OK=1
            ;;
        l)
            login
            OK=1
            ;;
        s)
            # Run a bash shell
            SHELL=bash
            OK=1
            ;;
        x)
            RUN=1
            OK=1
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
done

shift $(expr $OPTIND - 1 )

if [ -z "$OK" ]; then
    usage
    exit 1
fi

if [ ! -z "$COMPILE" ]; then
    compile
fi

if [ ! -z "$PUSH" ]; then
    push
fi

# Unless we create these now, docker will (owned by root)
mkdir -p $HOME/.cache/yarn
mkdir -p $HOME/.npm

# We pass in the current user's UID so docker can create a matching user.
# In this way, any files created are still owned by the current user.
# Note that the actual docker USERNAME doesn't matter, as long as UIDs match.
ID=$(id -u)
DOCKER_CMD=$( cat <<EOT
    docker run -it --rm \
        -v $BASE:$WORKDIR \
        -v $HOME/.cache/yarn:/cache/yarn \
        -v $HOME/.npm,dst=/cache/npm \
        -e LOCAL_USER_ID=$ID \
        $DOCKER_IMAGE_TAGGED
EOT
)

if [ ! -z "$SHELL"  ]; then
    set -x
    exec $DOCKER_CMD $SHELL
fi

if [ ! -z "$RUN"  ]; then
    set -x
    exec $DOCKER_CMD "$@"
fi
