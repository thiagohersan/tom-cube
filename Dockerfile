FROM node:8-stretch

RUN dpkg --add-architecture armhf
RUN apt-get update

RUN apt-get install -y arduino-core

RUN mkdir -p /tmp/build/tom-cube

WORKDIR /tmp/build
RUN git clone https://github.com/esp8266/Arduino.git esp8266
RUN git clone https://github.com/plerup/makeEspArduino.git
RUN git clone https://github.com/adafruit/Adafruit_NeoPixel.git libraries/Adafruit_NeoPixel

WORKDIR /tmp/build/makeEspArduino
RUN git fetch && git checkout tags/4.9.2 -b v4.9.2

WORKDIR /tmp/build/libraries/Adafruit_NeoPixel
RUN git fetch && git checkout tags/1.1.6 -b v1.1.6

WORKDIR /tmp/build/esp8266
RUN git fetch && git checkout tags/2.4.0 -b v2.4.0

WORKDIR /tmp/build/esp8266/tools
RUN python get.py

ADD *.h *.cpp *.ino /tmp/build/tom-cube/

WORKDIR /tmp/build/tom-cube

RUN git ls-remote https://github.com/thiagohersan/tom-cube.git | \
    grep refs/heads/master | cut -f 1 > /tmp/LATEST_COMMIT_HASH

RUN LATEST_COMMIT_HASH=$(cat /tmp/LATEST_COMMIT_HASH) && \
    sed -i "s/deadbeef/${LATEST_COMMIT_HASH}/g" tom-cube.h

WORKDIR /tmp/build
RUN make -f ./makeEspArduino/makeEspArduino.mk \
         ESP_ROOT=./esp8266 \
         CHIP=esp8266 \
         BOARD=nodemcuv2 \
         SKETCH=./tom-cube/tom-cube.ino \
         CUSTOM_LIBS=./libraries \
         EXCLUDE_DIRS=./libraries/Adafruit_NeoPixel/examples \
         BUILD_ROOT=./mkESP

CMD ["cp", "mkESP/tom-cube_nodemcuv2/tom-cube.bin", "/opt/tom-cube/bin"]
