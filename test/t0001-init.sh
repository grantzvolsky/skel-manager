#!/usr/bin/env bash

test_description="init command test"

source "setup.sh"

test_expect_success "skm init" "
    $SKM init &&
    [[ -d $SKEL_MANAGER_DIR ]] ||
    (ls -la $SKEL_MANAGER_DIR && false)
"

test_expect_success "Commands are chained this way" "
    test x = 'x' &&
    test 2 -gt 1 &&
    echo success
"

return_42() {
    echo "Will return soon"
    return 42
}

test_expect_success "You can test for a specific exit code" "
    test_expect_code 42 return_42
"

test_expect_failure "We expect this to fail" "
    test 1 = 2
"

test_done

# vi: set ft=sh.sharness :
