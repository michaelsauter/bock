#!/usr/bin/env bash
#
# Bock mocks binaries.
# https://github.com/michaelsauter/bock
#
# CAUTION: bock is just a proof-of-concept at this stage. It is by no means
#          feature complete or even correct in many cases. Use at your own risk.
#
# Sometimes, one might mock a binary instead of using the real one.
# An example use case is mocking "oc", the CLI binary to interact with OpenShift.
# OpenShift is, depending on the host, tricky to install and resource intensive.
# Using "bock", one can mock the interaction to avoid running an actual cluster.
#
# To use this script, copy it into a folder with the name of the binary to mock,
# e.g. "git" or "oc". Then prepend your $PATH with that folder in your test
# script. As an example, see tests/run.sh.
#
# "bock" works by storing the mocked interactions in a temporary file named
# ".bock-want" and the actual invocations in a file named ".bock-got", which can
# be compared by calling "mock --verify".
#
set -ue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INIT="no"
VERIFY="no"
RECEIVE=""
TIMES=""
RETURN_STDOUT=""
RETURN_STDERR=""
RETURN_STATUS=0

function usage {
    printf "Bock mocks binaries.\n\n"
    printf "Usage:\n\n"
    printf "\t--help\t\tPrint usage\n"
    printf "\n"
    printf "\t--init\t\tInit state\n"
    printf "\t--verify\tCheck interactions\n"
    printf "\n"
    printf "\t--receive\tDefine interaction\n"
    printf "\t--times\t\tHow often interaction is expected\n"
    printf "\t--stdout\tSTDOUT to return from the interaction\n"
    printf "\t--stderr\tSTDERR to return from the interaction\n"
    printf "\t--status\tExit code of the interaction\n"
}

if [[ "$#" -gt 0 && "$1" == "mock" ]]; then
    shift

    while [[ "$#" -gt 0 ]]; do
        case $1 in

        --help) usage; exit 0;;

        --receive) RECEIVE="$2"; shift;;
        --receive=*) RECEIVE="${1#*=}";;

        --stdout) RETURN_STDOUT="$2"; shift;;
        --stdout=*) RETURN_STDOUT="${1#*=}";;

        --stderr) RETURN_STDERR="$2"; shift;;
        --stderr=*) RETURN_STDERR="${1#*=}";;

        --status) RETURN_STATUS="$2"; shift;;
        --status=*) RETURN_STATUS="${1#*=}";;

        --times) TIMES="$2"; shift;;
        --times=*) TIMES="${1#*=}";;

        --init) INIT="yes";;

        --verify) VERIFY="yes";;

        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac; shift; done

    if [ "${INIT}" == "yes" ]; then
        rm "${SCRIPT_DIR}/.bock-want" &> /dev/null || true
        rm "${SCRIPT_DIR}/.bock-got" &> /dev/null || true
        touch "${SCRIPT_DIR}/.bock-want"
        touch "${SCRIPT_DIR}/.bock-got"
        exit 0
    fi

    if [ "${VERIFY}" == "yes" ]; then
        echo ""
        checks=0
        failures=0
        # check that we got everything we wanted the correct amount of times
        while read wantLine; do
            wantReceive=$(echo "${wantLine}" | cut -d "#" -f 1)
            wantTimes=$(echo "${wantLine}" | cut -d "#" -f 5)
            if [ "${wantTimes}" != "" ]; then
                checks=$((checks+1))
                gotTimes=$(grep -- "${wantReceive}" "${SCRIPT_DIR}/.bock-got" | wc -l | tr -d ' ')
                if [ "${wantTimes}" != "${gotTimes}" ]; then
                    echo "Want '${wantReceive}' ${wantTimes} times, got ${gotTimes}."
                    failures=$((failures+1))
                fi
            fi
        done <"${SCRIPT_DIR}/.bock-want"

        exitCode=0
        if [ "${failures}" -gt 0 ]; then
            echo ""
            echo "Received calls:"
            cat "${SCRIPT_DIR}/.bock-got"
            echo ""
            echo "ERROR (${failures} failed out of ${checks})"
            exitCode=1
        else
            echo ""
            echo "SUCCESS"
        fi

        rm "${SCRIPT_DIR}/.bock-want" || true
        rm "${SCRIPT_DIR}/.bock-got" || true
        exit ${exitCode}
    fi

    if [ -n "${RECEIVE}" ]; then
        echo "${RECEIVE}#${RETURN_STDOUT}#${RETURN_STDERR}#${RETURN_STATUS}#${TIMES}" >> "${SCRIPT_DIR}/.bock-want"
    fi
else
    if [ ! -f "${SCRIPT_DIR}/.bock-got" ]; then
        echo "Run '$0 mock --init' first"
        exit 1
    fi

    echo $@ >> "${SCRIPT_DIR}/.bock-got"

    while read wantLine; do
        wantReceive=$(echo "${wantLine}" | cut -d "#" -f 1)
        if [ "$wantReceive" == "$*" ]; then
            wantStdout=$(echo "${wantLine}" | cut -d "#" -f 2)
            if [ "${wantStdout}" != "" ]; then
                echo ${wantStdout}
            fi
            wantStderr=$(echo "${wantLine}" | cut -d "#" -f 3)
            if [ "${wantStderr}" != "" ]; then
                echo ${wantStderr} 1>&2
            fi
            wantStatus=$(echo "${wantLine}" | cut -d "#" -f 4)
            exit ${wantStatus}
        fi
    done <"${SCRIPT_DIR}/.bock-want"
    
fi
