#!/bin/bash

### Functions ###

# Dispaly help message
function display_help() {
    echo "Usage: $0 -n name -c color -d description -t api_token"
    echo ""
    echo "Options:"
    echo " -n, --name          specify label name         (required)"
    echo " -c, --color         specify label color        (required)"
    echo " -d, --description   specify label description  (required)"
    echo " -t, --api-token     specify api token          (required)"
    echo " -h, --help          display this help message and exit"
    echo ""
}

# Parse input
function parse_params() {
    TEMP=`getopt -o n:c:d:t:h --long name:,color:,description:,api-token:,help -n 'parse_params' -- "$@"`
    eval set -- "$TEMP"
    while true; do
        case "$1" in
            -n|--name)
                name="$2"
                shift 2
            ;;
            -c|--color)
                color="$2"
                shift 2
            ;;
            -d|--description)
                description="$2"
                shift 2
            ;;
            -t|--api-token)
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
    if [ -z "$name" ] || [ -z "$color" ] || [ -z "$description" ] || [ -z "$api_token" ]; then
        echo "Error: All options -n, -c, -d, -t are required"
        display_help
        exit 1
    fi
}

# Create a label
function create_label() {
    curl -s \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $api_token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$repo/labels \
    -d "{\"name\": \"$name\", \"description\": \"$description\" , \"color\": \"$color\"}"
}

# Update a label, if it does not exist create it
function update_label() {
    status_code=$(curl -s \
        -X PATCH \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $api_token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$repo/labels/$name \
        -d "{\"name\": \"$name\", \"description\": \"$description\" , \"color\": \"$color\"}" \
        --write-out '%{http_code}' \
    --output /dev/null)
    if [ "$status_code" -eq 404 ]; then
        create_label
        echo "Successfully created $name label in $repo"
    else
        echo "Successfully updated $name label in $repo"
    fi
}


### Script ###

# Parse and validate parameters
parse_params "$@"
validate_params

# Fetch all repositories and keep only their full names (user/repo)
repos=( $(curl -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $api_token" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
"https://api.github.com/user/repos" | jq -r '.[].full_name') )


# Update the specified label in every repository.
# If it does not exist then create it.
for repo in ${repos[@]}
do
    update_label
done