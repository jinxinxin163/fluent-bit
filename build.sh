#!/bin/bash
TARGET=fluent-bit
#REPO=registry.cn-shanghai.aliyuncs.com/advantech-k8s/
REPO=harbor.arfa.wise-paas.com/ensaas-logging/
TAG=1.2.0-3
docker build -t ${REPO}${TARGET}:${TAG} -f ./Dockerfile .
docker push ${REPO}${TARGET}:${TAG}
