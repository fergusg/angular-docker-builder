#!/bin/bash

export HERE=$(pwd)

# Suggest: fix version, vX.Y, not latest
IMAGE=fergusg/angular-docker-builder:latest
# Suggest: unique project name
CONTAINER=$(basename $HERE)

CI=${CI}

set -e
set -o nounset

# Unless we create these now, docker will (owned by root)
YARNDIR=$HOME/.cache/yarn
NPMDIR=$HOME/.npm
mkdir -p $YARNDIR $NPMDIR

DOCKER_ARGS=

# If we are interactive, set these opts so we can interrupt, etc.
test -t && DOCKER_ARGS=-it

# We pass in the current user's UID so docker can create a matching user.
ID=$(id -u)

DOCKER_CMD=$(cat <<EOT | xargs
    docker run $DOCKER_ARGS --rm \
        --name=$CONTAINER-$$ \
        --net=host \
        --mount type=bind,src=$HERE,dst=/workdir \
        --mount type=bind,src=$YARNDIR,dst=/cache/yarn \
        --mount type=bind,src=$NPMDIR,dst=/cache/npm \
        -e LOCAL_USER_ID=$ID \
        -e CI="$CI" \
        --cap-add=SYS_ADMIN \
        $IMAGE
EOT
)

test -f package.json && test ! -d node_modules && $DOCKER_CMD bash -c "exec yarn"
set -x
exec $DOCKER_CMD bash -c "exec $*"
