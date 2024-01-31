#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <repo> <username> <token>"
    exit 1
fi

repo=$1
username=$2
token=$3
page=1

# Use basename to strip out the organization name from the repo
repo_name=$(basename $repo)
output_file="${repo_name}-PRs.md"

echo "# Repository: $repo" > $output_file
echo "" >> $output_file

while true; do
    response=$(curl -s -H "Authorization: token $token" "https://api.github.com/repos/$repo/pulls?state=all&page=$page&sort=created&direction=asc")
    pr_count=$(echo "$response" | jq 'length')

    if [ "$pr_count" -eq 0 ]; then
        break
    fi

    for (( i=0; i<$pr_count; i++ )); do
        pr=$(echo "$response" | jq ".[$i]")
        pr_number=$(echo "$pr" | jq '.number')
        pr_title=$(echo "$pr" | jq -r '.title')
        pr_url=$(echo "$pr" | jq -r '.html_url')
        pr_date=$(echo "$pr" | jq -r '.created_at')
        formatted_date=$(date -d"$pr_date" +"%Y-%m-%d")

        commits=$(curl -s -H "Authorization: token $token" "https://api.github.com/repos/$repo/pulls/$pr_number/commits")
        commit_count=$(echo "$commits" | jq 'length')

        for (( j=0; j<$commit_count; j++ )); do
            commit=$(echo "$commits" | jq ".[$j]")
            commit_author=$(echo "$commit" | jq -r '.author.login')

            if [ "$commit_author" == "$username" ]; then
                commit_message=$(echo "$commit" | jq -r '.commit.message')
                echo "- [PR #$pr_number: $pr_title]($pr_url)" >> $output_file
                echo "  - Commit message: $commit_message" >> $output_file
                echo "  - Date: $formatted_date" >> $output_file
                echo "" >> $output_file
                break
            fi
        done
    done

    ((page++))
done

code $output_file