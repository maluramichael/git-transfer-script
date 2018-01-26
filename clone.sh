#!/bin/sh

destinationUser=""
repoList="repos.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do
  repo=${line##*/}
  echo "---------------------------------- CLONE REPO"
  git clone "git@github.com:$line.git $line"
  cd $line

  echo "---------------------------------- FETCH"
  git fetch --all

  echo "---------------------------------- TRACK"
  for remote in `git branch -r | awk '{print $1}'`; do git branch --track $remote; done

  echo "---------------------------------- PULL"
  git pull --all

  echo "---------------------------------- CREATE REPO ON GITHUB"
  hub create -p $destinationUser/$repo

  echo "---------------------------------- SET REMOTE"
  git remote set-url origin git@github.com:$destinationUser/$repo.git

  echo "---------------------------------- PUSH"
  git push --all
done < $repoList
