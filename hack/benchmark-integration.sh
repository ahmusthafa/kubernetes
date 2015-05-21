#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
BENCHMARK_REGEX=${BENCHMARK_REGEX:-"."}

source "${KUBE_ROOT}/hack/lib/init.sh"

cleanup() {
  kube::etcd::cleanup
  kube::log::status "Benchmark cleanup complete"
}

runTests() {
  kube::etcd::start
  kube::log::status "Running benchmarks"
  KUBE_GOFLAGS="-tags 'benchmark no-docker' -bench . -benchtime 1s -cpu 4" \
    KUBE_RACE="-race" \
    KUBE_TEST_API_VERSIONS="v1beta3" \
    KUBE_TIMEOUT="-timeout 10m" \
    KUBE_TEST_ETCD_PREFIXES="registry"\
    ETCD_CUSTOM_PREFIX="None" \
    KUBE_TEST_ARGS="-bench-quiet 0 -bench-pods 30 -bench-tasks 1"\
    "${KUBE_ROOT}/hack/test-go.sh" test/integration
  cleanup
}

# Run cleanup to stop etcd on interrupt or other kill signal.
trap cleanup EXIT

runTests