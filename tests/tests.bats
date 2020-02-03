#!/usr/bin/env bats

load singularity_helper

@test "singularity" {
    singularity --help
    [ "$?" -eq 0 ]
}

@test "tests file" {
    ls ${BATS_TEST_DIRNAME} | grep tests
    [ "$?" -eq 0 ]
}

@test "singularity exec" {
    result=$(sexec echo "hello world")
    [ "$result" == "hello world" ]
}

@test "singularity run" {
    srun
    result=$(sexec echo "$?")
    [ "$result" -eq 0 ]
}

@test "addition" {
    num=2
    result=$(($num + 2))
    [ "$result" -eq 4 ]
}

@test "string concat" {
    HELLO=hello
    WORLD=world
    result="${HELLO} ${WORLD}"
    [ "$result" == "hello world" ]
}
