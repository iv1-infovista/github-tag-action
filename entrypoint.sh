#!/bin/bash

set -o pipefail

# config
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION}
tag_context=${TAG_CONTEXT:-repo}
verbose=${VERBOSE:-true}

cd ${GITHUB_WORKSPACE}/${source}

echo "*** CONFIGURATION ***"
echo -e "\tSOURCE: ${source}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tINITIAL_VERSION: ${initial_version}"
echo -e "\tTAG_CONTEXT: ${tag_context}"
echo -e "\tVERBOSE: ${verbose}"

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "${current_branch}" != "master" ]]
    then
        echo "::error::Build number only applies on master branch not on" ${current_branch} "branch" 
  		exit 1
fi

# fetch tags
git fetch --tags

# get latest tag that looks like a semver (with or without v)
case "$tag_context" in
    *repo*) 
        tag=$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "^[0-9]{9}$" | head -n1)
        pre_tag=$tag
        ;;
    *branch*) 
        tag=$(git tag --list --merged HEAD --sort=-v:refname | grep -E "^[0-9]{9}$"  | head -n1)
        pre_tag=$tag
        ;;
    * ) echo "Unrecognised context" $tag_context; exit 1;;
esac

if [ -z "$initial_version" ]
then
	initial_version=$(date +"%Y%m000")
fi
# if there are none, start tags at INITIAL_VERSION which defaults to YEARMONTH000

if [ -z "$tag" ]
then
    log=$(git log --pretty='%B')
    tag="$initial_version"
    pre_tag="$initial_version"
    tag_commit=""
else
    log=$(git log $tag..HEAD --pretty='%B')
# get current commit hash for tag
    tag_commit=$(git rev-list -n 1 $tag)
fi

# get current commit hash
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo ::set-output name=tag::$tag
    exit 0
fi

# echo log if verbose is wanted
if $verbose
then
  echo $log
fi

new=$(($tag+1))

echo -e "Taging  ${current_branch} tag ${pre_tag} with new tag ${new}"

# set outputs
echo ::set-output name=new_tag::$new
echo ::set-output name=pre_tag::$pre_tag

# use dry run to determine the next tag
if $dryrun
then
    echo ::set-output name=tag::$tag
    exit 0
fi 

echo ::set-output name=tag::$new

# create local git tag
git tag $new

# push new tag ref to github
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')

echo "$dt: **pushing tag $new to repo $full_name"

git_refs_response=$(
curl -s -X POST $git_refs_url \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF
)

git_ref_posted=$( echo "${git_refs_response}" | jq .ref | tr -d '"' )

echo "::debug::${git_refs_response}"
if [ "${git_ref_posted}" = "refs/tags/${new}" ]; then
  exit 0
else
  echo "::error::Tag was not created properly."
  exit 1
fi
