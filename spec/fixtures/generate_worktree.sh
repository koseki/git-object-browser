#! /bin/sh

ROOT=`dirname $0`

DIR=$ROOT/worktree
rm -rf $DIR

mkdir $DIR
cd $DIR

export GIT_WORK_TREE=.
export GIT_DIR=_git

git init

cat > _git/config <<EOF
[user]
    name = git sample
    email = git@example.com

[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
    ignorecase = true
    excludesfile = _git/ignore
EOF

cat > _git/ignore <<EOF
*~
.DS_Store
_git
EOF

setdate() {
  export GIT_AUTHOR_DATE=2001-02-03T04:${1}Z
  export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
}

echo test > sample.txt
git add sample.txt
setdate "00:00"
git commit -m 'commit 0'

echo test1 > sample.txt
git add sample.txt
setdate "00:01"
git commit -m 'commit 1'

echo test2 > sample.txt
git add sample.txt
setdate "00:02"
git commit -m 'commit 2'

git gc

echo test3 > sample.txt
git add sample.txt
setdate "00:03"
git commit -m 'commit 3'

git tag -a test3-tag -m 'tag for commit 3'

echo test4 > sample.txt
git add sample.txt
setdate "00:04"
git commit -m 'commit 4'

git tag simple-tag

git branch branch-a
git branch branch-b

git checkout branch-a

echo test4a-1 > sample-a.txt
git add sample-a.txt
setdate "00:05"
git commit -m 'commit 4a-1'

echo test4a-2 > sample-a.txt
git add sample-a.txt
setdate "00:06"
git commit -m 'commit 4a-2'

git checkout branch-b

echo test4b-1 > sample-b.txt
git add sample-b.txt
setdate "00:07"
git commit -m 'commit 4b-1'

git checkout master

setdate "00:08"
git merge --no-ff branch-a -m 'merge a'

setdate "00:09"
mkdir subdir
touch subdir/sample-sub.txt
git add subdir/sample-sub.txt
git commit -m 'add subdir'
