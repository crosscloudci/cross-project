#!/bin/bash
#############################################################################
#
# Copyright © 2018 Amdocs. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#############################################################################
#

  echo "verify onap-config is 0/1 not 1/1 - as in completed - an error pod - means you are missing onap-parameters.yaml or values are not set in it."
  while [  $(kubectl get pods -n onap -a | grep config | grep 0/1 | grep Completed | wc -l) -eq 0 ]; do
    sleep 15
    echo "waiting for config pod to complete"
  done

  echo "wait for all pods up for 15-22 min"
  FAILED_PODS_LIMIT=0
  MAX_WAIT_PERIODS=120 # 22 MIN
  COUNTER=0
  while [  $(kubectl get pods --all-namespaces | grep 0/ | wc -l) -gt $FAILED_PODS_LIMIT ]; do
    PENDING=$(kubectl get pods --all-namespaces | grep 0/ | wc -l)
    sleep 15
    LIST_PENDING=$(kubectl get pods --all-namespaces | grep 0/ )
    echo "${LIST_PENDING}"
    echo "${PENDING} pending > ${FAILED_PODS_LIMIT} at the ${COUNTER}th 15 sec interval"
    COUNTER=$((COUNTER + 1 ))
    MAX_WAIT_PERIODS=$((MAX_WAIT_PERIODS - 1))
    if [ "$MAX_WAIT_PERIODS" -eq 0 ]; then
      FAILED_PODS_LIMIT=140
    fi
  done
  
  PENDING_COUNT_SO=$(kubectl get pods -n onap-mso | grep 0/ | wc -l)
  if [ "$PENDING_COUNT_SO" -gt 0 ]; then
    echo "down-so=${PENDING_COUNT_SO}"
  fi
  PENDING_COUNT_LOG=$(kubectl get pods -n onap-log | grep 0/ | wc -l)
  if [ "$PENDING_COUNT_LOG" -gt 0 ]; then
    echo "down-log=${PENDING_COUNT_LOG}"
  fi
  PENDING_COUNT_ROBOT=$(kubectl get pods -n onap-robot | grep 0/ | wc -l)
  if [ "$PENDING_COUNT_ROBOT" -gt 0 ]; then
    echo "down-robot=${PENDING_COUNT_ROBOT}"
  fi

  echo "check filebeat 2/2 count for ELK stack logging consumption"
  FILEBEAT=$(kubectl get pods --namespace=onap-mso -a | grep 2/)
  echo "${FILEBEAT}"
  echo "sleep 4 min - to allow rest frameworks to finish"
  sleep 240
  echo "run healthcheck 3 times to warm caches and frameworks so rest endpoints report properly - see OOM-447"

  # OOM-484 - robot scripts moved
  helm init --service-account tiller
  helm repo add onap-amsterdam  http://cncf.gitlab.io/onap-amsterdam
  helm fetch onap-amsterdam/robot
  tar -xvf robot-*.tgz
  cd robot

  echo "run healthcheck prep 1"
  ./ete-k8s.sh health > ~/health1.out
  echo "run healthcheck prep 2"
  ./ete-k8s.sh health > ~/health2.out
  echo "run healthcheck for real - wait a further 6 min"
  sleep 5
  ./ete-k8s.sh health
