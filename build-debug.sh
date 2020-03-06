#!/bin/bash
TARGET=fluent-bit
REPO=registry.cn-shanghai.aliyuncs.com/advantech-k8s/
TAG=1.2.0-debug
docker build -t ${REPO}${TARGET}:${TAG} -f ./Dockerfile.debug .
docker push ${REPO}${TARGET}:${TAG}

