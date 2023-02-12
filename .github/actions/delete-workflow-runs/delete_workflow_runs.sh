#!/bin/bash

### Functions ###

# Dispaly help message
function display_help() {
    echo "Usage: $0 -o owner -r repo -a api_token"
    echo ""
    echo "Options:"
    echo " -o, --owner         specify repository owner   (required)"
    echo " -r, --repo          specify repository name    (required)"
    echo " -a, --api-token     specify api token          (required)"
    echo " -h, --help          display this help message and exit"
    echo ""
}

# Parse input
function parse_params() {
    TEMP=`getopt -o o:r:a:h --long owner:,repo:,api-token:,help -n 'parse_params' -- "$@"`
    eval set -- "$TEMP"
    while true; do
        case "$1" in
            -o|--owner)
                owner="$2"
                shift 2
            ;;
            -r|--repo)
                repo="$2"
                shift 2
            ;;
            -a|--api-token)
                api_token="$2"
                shift 2
            ;;
            -h|--help)
                display_help
                exit 0
            ;;
            --)
                shift
                break
            ;;
            *)
                echo "Internal error!"
                display_help
                exit 1
            ;;
        esac
    done
}

# Check if all required options are provided
function validate_params() {
    if [ -z "$owner" ] || [ -z "$repo" ] || [ -z "$api_token" ]; then
        echo "Error: All options -o, -r, -a are required"
        display_help
        exit 1
    fi
}

# Delete a workflow run id
function delete_run() {
    curl -s \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $api_token"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$owner/$repo/actions/runs/$1
    echo "Successfully deleted a workflow's run with $1"
}


### Script ###

# Parse and validate parameters
parse_params "$@"
validate_params

# List the runs of all the workflows and get their ids
run_ids=( $(curl -s \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $api_token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$owner/$repo/actions/runs?per_page=100" | jq -r '.workflow_runs[].id') )

# Delete all runs
for id in ${run_ids[@]}
do
    delete_run $id
done