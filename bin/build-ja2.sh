#! /bin/sh

ROOT=`dirname $0`/..

LNG=ja

# コミット日付を揃えます。
export GIT_AUTHOR_DATE=2001-02-03T04:00:00Z
export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE

# 各ディレクトリを初期化します。
WORK_BARE=tmp/bare
WORK_REPO1=tmp/repo1
WORK_REPO2=tmp/repo2

DUMP_BARE=${LNG}-bare
DUMP_REPO1=${LNG}-repo1
DUMP_REPO2=${LNG}-repo2

rm -rf $WORK_BARE
rm -rf $WORK_REPO1
rm -rf $WORK_REPO2
rm -rf $DUMP_BARE
rm -rf $DUMP_REPO1
rm -rf $DUMP_REPO2

mkdir -p $WORK_BARE
mkdir -p $WORK_REPO1
mkdir -p $WORK_REPO2

cd $WORK_BARE
git init --bare

# [bare] step1
git object-browser --dump ../../$DUMP_BARE --step step1

cd ..

for REPO in repo1 repo2
do
    git clone bare $REPO
    cat >> $REPO/.git/config <<EOF
[user]
    name = KOSEKI Kengo
    email = koseki@example.com
EOF
done

cd repo1

# [repo1] step2
git object-browser --dump ../../$DUMP_REPO1 --step step2

touch a.txt
git add a.txt
git commit -m '最初のファイル a.txt をコミットしました。'

# [repo1] step3
git object-browser --dump ../../$DUMP_REPO1 --next

git push origin master

# [repo1] step4
git object-browser --dump ../../$DUMP_REPO1 --next

cd ../bare

# [bare] step5
git object-browser --dump ../../$DUMP_BARE --step step5 --diff ../../$DUMP_BARE/json/step1

cd ../repo1

git branch step6-a
git branch step6-b
git checkout step6-a
echo aaa > a.txt
git add a.txt
git commit -m 'step6-a ブランチで a.txt に aaa と書き込みました。'
git checkout step6-b
echo bbb > a.txt
git add a.txt
git commit -m 'step6-b ブランチで a.txt に bbb と書き込みました。'

# [repo1] step6
git object-browser --dump ../../$DUMP_REPO1 --step step6 --diff ../../$DUMP_REPO1/json/step4

git push origin step6-a

# [repo1] step7
git object-browser --dump ../../$DUMP_REPO1 --next

cd ../bare

# [bare] step8
git object-browser --dump ../../$DUMP_BARE --step step8 --diff ../../$DUMP_BARE/json/step5

cd ../repo1
git push origin step6-b

# [repo1] step9
git object-browser --dump ../../$DUMP_REPO1 --step step9 --diff ../../$DUMP_REPO1/json/step7

cd ../bare

# [bare] step10
git object-browser --dump ../../$DUMP_BARE --step step10 --diff ../../$DUMP_BARE/json/step8

cd ../repo2

# [repo2] step11
git object-browser --dump ../../$DUMP_REPO2 --step step11

git pull origin master

# [repo2] step12
git object-browser --dump ../../$DUMP_REPO2 --next

git fetch origin step6-b

# [repo2] step13
git object-browser --dump ../../$DUMP_REPO2 --next

git pull origin step6-a

# [repo2] step14
git object-browser --dump ../../$DUMP_REPO2 --next

git gc

# [repo2] step15
git object-browser --dump ../../$DUMP_REPO2 --next

cd ../..

# ノート・設定をコピーします。
cp -r src/$DUMP_BARE/notes/*.html $DUMP_BARE/notes
cp -r src/$DUMP_REPO1/notes/*.html $DUMP_REPO1/notes
cp -r src/$DUMP_REPO2/notes/*.html $DUMP_REPO2/notes
cp -r src/$DUMP_BARE/config.js $DUMP_BARE
cp -r src/$DUMP_REPO1/config.js.html $DUMP_REPO1
cp -r src/$DUMP_REPO2/config.js $DUMP_REPO2

function normalize() {
    DIR=$1

    find $DIR/json -name '*.json' | xargs ruby -pne 'gsub(/^(\s+)"(ctime|mtime|ino)":\s+\d+,$/, %{\\1"\\2": 1356966000,})' -i
    find $DIR/json -name 'index.json' -maxdepth 2 | xargs ruby -pne 'gsub(/^    "sha1": "[0-9a-f]{40}"$/, %{    "sha1": "-"})' -i
    find $DIR/json -name 'index.json' -maxdepth 2 | xargs ruby -pne 'gsub(/^        "dev": \d+,$/, %{        "dev": 234881026,})' -i
    find $DIR/json -name 'index.json' -maxdepth 2 | xargs ruby -pne 'gsub(/^        "uid": \d+,$/, %{        "uid": 501,})' -i
    find $DIR/json -name 'index.json' -maxdepth 2 | xargs ruby -pne 'gsub(/^        "gid": \d+,$/, %{        "gid": 20,})' -i
    find $DIR/json -name 'config.json' -maxdepth 2 | xargs ruby -pne 'gsub(%r{\\turl = .+?/tmp/bare}, %{\\turl = /path/to/bare})' -i
}

normalize $DUMP_BARE
normalize $DUMP_REPO1
normalize $DUMP_REPO2
