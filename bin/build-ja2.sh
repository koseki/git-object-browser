#! /bin/sh

ROOT=`dirname $0`/..

LNG=ja

setdate() {
  export GIT_AUTHOR_DATE=2001-02-03T04:${1}Z
  export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
}
setdate "00:00"

cd $ROOT
WORK_BARE=tmp/bare.git
WORK_REPO1=tmp/repo-a
WORK_REPO2=tmp/repo-b
rm -rf $WORK_BARE
rm -rf $WORK_REPO1
rm -rf $WORK_REPO2

mkdir -p $WORK_BARE
mkdir -p $WORK_REPO1
mkdir -p $WORK_REPO2

DUMP_BARE=${LNG}-bare
DUMP_REPO1=${LNG}-repo1
DUMP_REPO2=${LNG}-repo2
# SRC_BARE=../../src/${LNG}-bare

rm -rf $DUMP_BARE
rm -rf $DUMP_REPO1
rm -rf $DUMP_REPO2

cd $WORK_BARE
git init --bare

git object-browser --dump ../../$DUMP_BARE --next

cd ..
git clone bare.git repo-a
git clone bare.git repo-b

cd repo-a
git object-browser --dump ../../$DUMP_REPO1 --next

touch a.txt
git add a.txt
git commit -m '最初のファイル a.txt をコミットしました。'

git object-browser --dump ../../$DUMP_REPO1 --next

git push origin master

git object-browser --dump ../../$DUMP_REPO1 --next

cd ../bare.git

git object-browser --dump ../../$DUMP_BARE --next


cd ../repo-b

# repo2 step1
git object-browser --dump ../../$DUMP_REPO2 --next

git pull origin master

# repo2 step2
git object-browser --dump ../../$DUMP_REPO2 --next

git pull origin

# repo2 step3
git object-browser --dump ../../$DUMP_REPO2 --next


exit

cat > .git/config <<EOF
[user]
    name = KOSEKI Kengo
    email = koseki@example.com

[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
    ignorecase = true
EOF

