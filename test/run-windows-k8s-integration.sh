#!/bin/bash

# Optional environment variables
# GCE_PD_OVERLAY_NAME: which Kustomize overlay to deploy with
# GCE_PD_DO_DRIVER_BUILD: if set, don't build the driver from source and just
#   use the driver version from the overlay
# GCE_PD_BOSKOS_RESOURCE_TYPE: name of the boskos resource type to reserve

set -o nounset
set -o errexit

readonly PKGDIR=${GOPATH}/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver
readonly overlay_name="${GCE_PD_OVERLAY_NAME:-stable-master}"
readonly do_driver_build="${GCE_PD_DO_DRIVER_BUILD:-true}"
readonly deployment_strategy=${DEPLOYMENT_STRATEGY:-gce}
readonly test_version=${TEST_VERSION:-master}
readonly gce_zone=${GCE_CLUSTER_ZONE:-us-central1-b}
readonly teardown_driver=${GCE_PD_TEARDOWN_DRIVER:-true}
readonly use_kubetest2=${USE_KUBETEST2:-true}

make -C "${PKGDIR}" test-k8s-integration

if [ "$use_kubetest2" = true ]; then
    export GO111MODULE=on;
    go get sigs.k8s.io/kubetest2@latest;
    go get sigs.k8s.io/kubetest2/kubetest2-gce@latest;
    go get sigs.k8s.io/kubetest2/kubetest2-gke@latest;
    go get sigs.k8s.io/kubetest2/kubetest2-tester-ginkgo@latest;
fi

base_cmd="${PKGDIR}/bin/k8s-integration-test \
            --platform=windows --bringup-cluster=false --teardown-cluster=false --teardown-driver=${teardown_driver}\
            --run-in-prow=true --deploy-overlay-name=${overlay_name} --service-account-file=${E2E_GOOGLE_APPLICATION_CREDENTIALS} \
            --do-driver-build=${do_driver_build} --gce-zone=${gce_zone} --test-version=${test_version}\
            --storageclass-files=sc-windows.yaml --snapshotclass-file=pd-volumesnapshotclass.yaml --test-focus='External.Storage' \
            --deployment-strategy=${deployment_strategy} --use-kubetest2=${use_kubetest2}"

eval "$base_cmd"
