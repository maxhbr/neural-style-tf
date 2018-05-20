#!/usr/bin/env bash
# Copyright 2016 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT

set -x

docker rm --force nstf >/dev/null 2>&1

set -e

cd $(dirname $0)
wget -nc http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-19.mat

_update="apt-get update"
_install="apt-get install -y --no-install-recommends"
_cleanup="eval apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
_purge="apt-get purge -y --auto-remove"
docker build -t nstf --rm=true --force-rm=true -f - . <<EOF
FROM tensorflow/tensorflow:latest
MAINTAINER oss@maximilian-huber.de
RUN $_update \
 && $_install python-opencv wget \
 && $_cleanup
ADD . /neutral-style-tf
WORKDIR /neutral-style-tf
VOLUME /neutral-style-tf/image_output
EOF

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist :0 \
    | sed -e 's/^..../ffff/' \
    | xauth -f $XAUTH nmerge -

# input="./image_input/lion.jpg"
input="./image_input/face.jpg"
# style="./styles/kandinsky.jpg"
style="./styles/seated-nude.jpg"

mkdir -p ./image_output
time docker run -ti \
       -v "$XSOCK":"$XSOCK" -e DISPLAY="$DISPLAY" \
       -v "$XAUTH":"$XAUTH" -e XAUTHORITY="$XAUTH" \
       -v "$(readlink -f ./image_output):/neutral-style-tf/image_output" \
       --name=nstf \
       nstf ${1:-bash stylize_image.sh $input $style}
