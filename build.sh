#!/bin/bash
TARGET=fluent-bit
REPO=registry.cn-shanghai.aliyuncs.com/advantech-k8s/
TAG=1.2.0-1
docker build -t ${REPO}${TARGET}:${TAG} -f ./Dockerfile .
docker push ${REPO}${TARGET}:${TAG}

