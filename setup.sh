#!/bin/bash

set -eo pipefail

dir=$(dirname $0)
source $dir/.includes.sh

kubectl create namespace otel \
  --dry-run=client -o yaml | kubectl apply -f -

check_helm_chart "open-telemetry/opentelemetry-operator"

echo "setting up opentelemetry-operator"

kubectl get secrets -n logging ofd-opensearch-certificates -o json | jq '.data."tls.crt"' | sed 's/"//g' | base64 -d > $dir/ca.crt
kubectl create secret generic ofd-ca --from-file $dir/ca.crt -n otel \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f $dir/ca.crt

helm upgrade otel-operator open-telemetry/opentelemetry-operator \
  -n otel -f $dir/operator.yaml \
  --install --wait --timeout 15m

for var in "$@"
do

  if [[ "$var" = "--with-operator-collector" ]]; then
    kubectl apply -f $dir/collector.yaml
  fi
done

if [ -z "$@" ]; then

    check_helm_chart "open-telemetry/opentelemetry-collector"
    echo "setting up opentelemetry-collector"

    helm upgrade otel-collector open-telemetry/opentelemetry-collector \
       -n otel -f $dir/collector-helm.yaml \
       --install --timeout 15m
fi

