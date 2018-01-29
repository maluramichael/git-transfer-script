#!/bin/sh

destinationUser="" # user to create repo for
token="" # token with repo permissions
filters="." # grep -E regex filter, "." for everything
entityType="o" # o for organisation, u for user
entity="" # organisation name or usename

if [ "$destinationUser" == "" ]; then
  echo "destinationUser not set" 1>&2
  exit 128
fi

if [ "$token" == "" ]; then
  echo "token not set" 1>&2
  exit 128
fi

if [ "$filters" == "" ]; then
  echo "filters not set" 1>&2
  exit 128
fi

if [ "$entity" == "" ]; then
  echo "entity not set" 1>&2
  exit 128
fi

getRepos() {
  if [ "$1" = "o" ]
    then type="orgs"
    else type="users"
  fi

  all_names=$(echo $(getReposPage $type $2 1) | jq 'join("\n")')
  all_names=$(echo $all_names | sed -e 's/"//g' | grep -E $filters)

  echo $all_names
}

getReposPage() {
  page=$3

  url="https://api.github.com/$1/$2/repos?per_page=100&page=$3"
  res=$(curl "$url" -H "Authorization: bearer $token" 2>/dev/null)

  length=$(echo $res | jq '. | length')
  names=$(echo $res | jq 'map(.full_name)')

  if (($length > 0)) && (($length % 100 == 0))
    then
      names="$(echo $(echo $names)$(getReposPage $1 $2 $(($3 + 1))) | jq -s '[.[][]]')"
  fi

  echo $names
}

repos=$(getRepos $entityType $entity)

for line in $repos; do
  repo=${line##*/}
  echo "---------------------------------- CLONE REPO"
  rm -rf $line
  git clone "git@github.com:$line.git" $line
  cd $line

  echo "---------------------------------- FETCH"
  git fetch --all

  echo "---------------------------------- TRACK"
  prefix="origin/"
  for remote in `git branch -r | awk '{print $1}' | grep -vv HEAD | grep $prefix`; do
    branch=${remote#$prefix}
    git branch --track $branch
  done

  echo "---------------------------------- PULL"
  git pull --all

  echo "---------------------------------- CREATE REPO ON GITHUB"
  hub create -p $destinationUser/$repo

  echo "---------------------------------- SET REMOTE"
  git remote set-url origin git@github.com:$destinationUser/$repo.git

  echo "---------------------------------- PUSH"
  git push --all
  cd ../..

done
