# Base Docker File
FROM ubuntu:18.04
LABEL author "fergus@gooses.co.uk"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y upgrade
RUN apt-get update
RUN apt-get install -y apt-utils apt-transport-https wget gnupg2 curl

#<BUILD PACKAGES>#########
# These should all be removed in "CLEAN" at the end
RUN apt-get install -y gcc make xz-utils git libpng-dev g++ pkg-config

#<EXTRAS>################
RUN apt-get install rsync rpm file -y
# compression goodies
RUN apt-get install -y webp zopfli brotli

#########################
# This is important magic.   Since docker runs as root, anything it creates
# (in the host file-system, via injected volumes) will normally be owned by root.
# The below creates a user with the same UID as the current user and then (via
# entrypoint.sh below) subsequent command are run as if by that user, thus
# preserving file ownership.
#
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
# HANDLING PERMISSIONS WITH DOCKER VOLUMES
#
# SUDO would do, su-exec avoids extra depth in the process tree.
#
COPY su-exec /tmp/su-exec
RUN cd /tmp/su-exec && make && cp su-exec /usr/local/bin

#<CHROME>##########
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN apt-get update && apt-get install -y google-chrome-stable

#<NODE>##################
ENV node_version=12.17.0
RUN curl -Ls https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz -o /tmp/node.tar.xz && ls -l /tmp/node.tar.xz
RUN tar -Jxf /tmp/node.tar.xz && rm -rf /tmp/node.tar.xz
RUN cp -rp /node-v*/* /usr/local/ && rm -rf /node-v*

#<YARN>##################
ENV yarn_version=1.22.4
RUN curl -L https://github.com/yarnpkg/yarn/releases/download/v${yarn_version}/yarn_${yarn_version}_all.deb -o /tmp/yarn.deb
RUN dpkg -i /tmp/yarn.deb && rm /tmp/yarn.deb

#<ANGULAR-CLI>##########
ENV ng_version=9.1.7
RUN yarn global add @angular/cli@${ng_version}
RUN yarn global add sass
RUN ng config -g cli.packageManager yarn

# Avoid downloading Chromium every time we test as we don't use it.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1

RUN apt-get install sudo -y

#<CLEAN>########################################################
RUN apt-get remove -y gcc make xz-utils git libpng-dev g++ pkg-config
RUN apt-get autoremove -y
RUN apt-get clean

RUN echo "NODE: $node_version; YARN: $yarn_version; NGCLI: $ng_version" > /versions.txt

#<ENDPIECE>##############
WORKDIR /workdir
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
