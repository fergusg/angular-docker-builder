#!/bin/bash
# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or fallback

USER_ID=${LOCAL_USER_ID:-9001}

useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
export HOME=/home/user
usermod -aG sudo user
echo "user            ALL = (ALL) NOPASSWD: ALL" >>  /etc/sudoers

mkdir -p /cache/yarn
chown user /cache/yarn
export YARN_CACHE_FOLDER=/cache/yarn
mkdir -p /cache/npm
chown user /cache/npm
su-exec user npm config set cache /cache/npm
touch $HOME/.sudo_as_admin_successful

echo -n "UID: $USER_ID; "
cat /versions.txt

exec su-exec user "$@"
