#! /bin/sh

ROOT=`dirname $0`/..

LNG=ja
DIR=$ROOT/tmp/worktree
rm -rf $DIR

mkdir -p $DIR
cd $DIR

DUMP_DIR=../../$LNG
SRC_DIR=../../src/$LNG

rm -r $DUMP_DIR

git init

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

setdate() {
  export GIT_AUTHOR_DATE=2001-02-03T04:${1}Z
  export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
}

# step1
git object-browser --dump $DUMP_DIR --next

echo first file > a.txt

git add a.txt

# step2
git object-browser --dump $DUMP_DIR --next

setdate "00:00"
git commit -m 'step3 で最初のファイル a.txt をコミットしました。'

# step3
git object-browser --dump $DUMP_DIR --next

rm -r $DUMP_DIR/notes
cp -r $SRC_DIR/notes $DUMP_DIR/notes
cp $SRC_DIR/config.js $DUMP_DIR/config.js

echo second file > b.txt
git add b.txt
git commit -m 'step4 で b.txt をコミットしました。'

# step4
git object-browser --dump $DUMP_DIR --next

git branch step5

# step5
git object-browser --dump $DUMP_DIR --next


git checkout step5

# step6
git object-browser --dump $DUMP_DIR --next

touch c.txt
git add c.txt
git commit -m 'step7 で空のファイル c.txt を追加しました。'

# step7
git object-browser --dump $DUMP_DIR --next

git checkout master
git merge step5

# step8
git object-browser --dump $DUMP_DIR --next

git reset --hard 'HEAD^'

# step9
git object-browser --dump $DUMP_DIR --next

git reset --hard 0b48b13

# step10
git object-browser --dump $DUMP_DIR --next

touch d.txt
git add d.txt
git commit -m 'step11 で空のファイル d.txt を追加しました。'

# step11
git object-browser --dump $DUMP_DIR --next

git merge step5 -m 'step12 で master に step5 をマージしました。'

# step12
git object-browser --dump $DUMP_DIR --next

git remote add gist https://gist.github.com/7074135.git

# step13
git object-browser --dump $DUMP_DIR --next

git fetch gist

# step14
git object-browser --dump $DUMP_DIR --next

git merge remotes/gist/master -m 'step15 で master に remotes/gist/master をマージしました。'

# step15
git object-browser --dump $DUMP_DIR --next

git tag step16

# step16
git object-browser --dump $DUMP_DIR --next

git tag -a step17 -m 'step17 で annotated タグを作成しました。'

# step17
git object-browser --dump $DUMP_DIR --next

echo aaa > a.txt
echo bbb > b.txt
git add a.txt
git stash

# step18
git object-browser --dump $DUMP_DIR --next

echo zzz > a.txt
git stash

# step19
git object-browser --dump $DUMP_DIR --next

git stash pop

# step20
git object-browser --dump $DUMP_DIR --next

git reset --hard HEAD
git stash pop --index

# step21
git object-browser --dump $DUMP_DIR --next

git reset --hard HEAD

mkdir dir1 dir2
touch dir1/empty.txt dir2/empty.txt
git add .
git ci -m 'step22 でディレクトリを2つ追加しました。'

# step22
git object-browser --dump $DUMP_DIR --next

echo xxx > dir2/x.txt
git add dir2/x.txt
git commit -m 'step23 で dir2 に x.txt を追加しました。'

# step23
git object-browser --dump $DUMP_DIR --next

git checkout -b step24

echo xxx > a.txt
git commit -am 'step24 ブランチにコミットしました。'

git checkout master

echo aaa > b.txt
git commit -am 'step24 で master ブランチにコミットしました。その1。'

echo bbb> b.txt
git commit -am 'step24 で master ブランチにコミットしました。その2。'

# step24
git object-browser --dump $DUMP_DIR --next

git rebase step24

# step25
git object-browser --dump $DUMP_DIR --next

git checkout remotes/gist/master

# step26
git object-browser --dump $DUMP_DIR --next

touch detached.txt
git add detached.txt
git commit -m 'detached HEAD 状態で detached.txt をコミットしました。'

# step27
git object-browser --dump $DUMP_DIR --next

git checkout -b step28

# step28
git object-browser --dump $DUMP_DIR --next

find $DUMP_DIR -name '*.json' | xargs ruby -pne 'gsub(/^(\s+)"(ctime|mtime|ino)":\s+\d+,$/, %{\\1"\\2": 1356966000,})' -i

find $DUMP_DIR/json -name 'index.json' -maxdepth 2 | xargs ruby -pne 'gsub(/^    "sha1": "[0-9a-f]{40}"$/, %{    "sha1": "-"})' -i


