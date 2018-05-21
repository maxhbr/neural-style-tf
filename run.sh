#!/usr/bin/env bash
# Copyright 2016 Maximilian Huber <oss@maximilian-huber.de>
# SPDX-License-Identifier: MIT
docker rm --force nstf >/dev/null 2>&1

set -e

cd $(dirname $0)
wget -nc http://www.vlfeat.org/matconvnet/models/imagenet-vgg-verydeep-19.mat

cat <<EOF > .dockerignore
examples
image_output
video_input
other*
EOF

cat <<'EOF' > entrypoint.sh
#!/usr/bin/env bash
set -e

cd /neutral-style-tf

device='/cpu:0'
# device='/gpu:0'

content_image="$1"
content_dir=$(dirname "$content_image")
content_filename=$(basename "$content_image")

style_image="$2"
style_dir=$(dirname "$style_image" )
style_filename=$(basename "$style_image")

echo "Rendering stylized image. This may take a while..."
set -x
python neural_style.py \
    --content_img "${content_filename}" --content_img_dir "${content_dir}" \
    --style_imgs "${style_filename}" --style_imgs_dir "${style_dir}" \
    --max_size 1920 \
    --max_iterations 10 \
    --device "${device}" \
    --verbose;
EOF

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
RUN chmod +x /neutral-style-tf/entrypoint.sh
EOF

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist :0 \
    | sed -e 's/^..../ffff/' \
    | xauth -f $XAUTH nmerge -

input=${1:-./image_input/face.jpg}
style=${2:-./styles/shipwreck.jpg}

mkdir -p ./image_output
mkdir -p ./other_image_input
mkdir -p ./other_styles
time docker run -ti \
     -v "$XSOCK":"$XSOCK" -e DISPLAY="$DISPLAY" \
     -v "$XAUTH":"$XAUTH" -e XAUTHORITY="$XAUTH" \
     -v "$(readlink -f ./image_output):/neutral-style-tf/image_output" \
     -v "$(readlink -f ./other_image_input):/neutral-style-tf/other_image_input" \
     -v "$(readlink -f ./other_styles):/neutral-style-tf/other_styles" \
     --name=nstf \
     nstf \
     /neutral-style-tf/entrypoint.sh $input $style

mv ./image_output/result ./image_output/result-$(date +%s)
