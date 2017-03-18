#!/usr/bin/env bats

load helpers

function setup() {
    clear_call_count

}
function teardown() {
    clear_call_count
}

@test '#install_packages_with_yum should call install_packages_on_redhat by passing "yum" and packages' {

    function install_packages_on_redhat() {
        increment_call_count "install_packages_on_redhat"
    }
    run install_packages_with_yum vim git

    echo "$output"
    [[ "$status" -eq 0 ]]
    [[ "$(call_count install_packages_on_redhat)" -eq 1 ]]
}



