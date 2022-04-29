#!/bin/bash

set -eo pipefail

dir=$(dirname $0)
source $dir/.includes.sh

check_executables
check_helm_chart "open-telemetry/opentelemetry-collector"

echo "setting up opentelemetry-collector"

kubectl create namespace otel \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade otel-collector open-telemetry/opentelemetry-collector \
  -n otel -f $dir/collector.yaml \
  --install --timeout 15m

check_helm_chart "open-telemetry/opentelemetry-operator"

echo "setting up opentelemetry-operator"

helm upgrade otel-operator open-telemetry/opentelemetry-operator \
  -n otel -f $dir/operator.yaml \
  --install --timeout 15m  