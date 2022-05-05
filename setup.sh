#!/bin/bash

set -eo pipefail

dir=$(dirname $0)
source $dir/.includes.sh

kubectl create namespace otel \
  --dry-run=client -o yaml | kubectl apply -f -

check_helm_chart "open-telemetry/opentelemetry-operator"

echo "setting up opentelemetry-operator"

helm upgrade otel-operator open-telemetry/opentelemetry-operator \
  -n otel -f $dir/operator.yaml \
  --install --wait --timeout 15m

kubectl apply -f $dir/collector.yaml

