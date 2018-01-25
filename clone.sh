#!/bin/sh

fromUser=""
destinationUser=""
repoList="repos.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do
  echo "---------------------------------- CLONE REPO"
  git clone "git@github.com:$fromUser/$line.git"
  cd $line

  echo "---------------------------------- FETCH"
  git fetch --all

  echo "---------------------------------- TRACK"
  for remote in `git branch -r | awk '{print $1}'`; do git branch --track $remote; done

  echo "---------------------------------- PULL"
  git pull --all

  echo "---------------------------------- CREATE REPO ON GITHUB"
  hub create -p $destinationUser/$line

  echo "---------------------------------- SET REMOTE"
  git remote set-url origin git@github.com:$destinationUser/$line.git

  echo "---------------------------------- PUSH"
  git push --all
done < $repoList