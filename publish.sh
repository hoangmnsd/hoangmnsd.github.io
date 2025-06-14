#!/bin/bash

pwd

echo "============Get environment variable from CircleCI"
# token is a env variable in circleci, also a personal access token from github
# this token has granted access to push commit to repo
export GH_PAT_TOKEN_MINIMO=$gh_pat_token_minimo
export GH_PAT_TOKEN_THE404=$gh_pat_token_the404

echo "============Duplicate folder ./posts,.."
# so I can create a private place that have only 1 password for all md file
cp -rp ./content/posts ./content/bk

echo "============Remove tags&categories params in all contents of bk folder"
# sed search for "tags: " and replace by "#tags: "
find ./content/bk -name '*.md' -exec sed -i -e 's/tags: /#tags: /g' {} \;
find ./content/bk -name '*.md' -exec sed -i -e 's/categories: /#categories: /g' {} \;

echo "============Delete unnecessary dir"
rm -rf ./content/bk/res ./content/bk/_index.md

echo "============Clone public repo"
git clone https://github.com/hoangmnsd/hoangmnsd.github.io.git
echo "============Re-generate the source code to hoangmnsd.github.io folder"
rm -rf ./hoangmnsd.github.io/* ./hoangmnsd.github.io/.circleci
echo "============Hugo generate"
hugo -d hoangmnsd.github.io
echo "============Direct to hoangmnsd.github.io"
cd hoangmnsd.github.io

echo "============Check version of openssl"
/usr/bin/openssl version

echo "============Install staticrypt"
TMP_DIR=$(mktemp -d)
REPO_URL="https://github.com/robinmoisson/staticrypt.git"
TAG="v2.4.0"
echo "Cloning staticrypt tag ${TAG} into ${TMP_DIR}..."
git clone --branch "${TAG}" --depth 1 "${REPO_URL}" "${TMP_DIR}/staticrypt"
cd "${TMP_DIR}/staticrypt"
echo "Pinning yargs dependency to ^10.0.3 in package.json..."
if command -v jq > /dev/null 2>&1; then
  jq '.dependencies.yargs="^10.0.3"' package.json > package.json.tmp && mv package.json.tmp package.json
else
  sed -i.bak -E 's#("yargs":\s*")>=?10(\.[0-9]+\.[0-9]+")#\1^10.0.3"#' package.json
fi
echo "Installing dependencies..."
npm install
echo "Linking the package globally..."
npm link
echo "Cleaning up..."
cd /root/project
rm -rf "$TMP_DIR"
# To using staticrypt should use absolute path, here need to improve
/usr/bin/staticrypt --version

# Each post in SCAN_LIST folder will have unique password
echo "============Set variables"
SCAN_LIST="posts secrets cv love family"
# This password is for encrypt and decrypt by openssl
PASSWORD="Messineverdie!!!4649"

echo "============Remove .tmp file"
rm -rf ./*.tmp

echo "============Loop the list of dir, list dirs startswith encrypt-*"
for dir in $SCAN_LIST;
do
    echo "Scanning this dir: ${dir}"
    find ./${dir} -type d -iname encrypt-\* >> encryptDirList.tmp
done
echo "List encrypt dirs: "
cat ./encryptDirList.tmp

echo "============Read above file, Loop each line"
while read p; do
  # Get last 4 digits
  last_4_digit=${p:(-4)}
  # echo "Last 4 digits: ${last_4_digit}" # DEBUG
  # Use openssl to encrypt 4 digits to a base64 string (full_secret)
  full_secret=$(echo -n "${last_4_digit}" | openssl enc -aes-256-cbc -pass pass:"${PASSWORD}" -e -base64 -nosalt -md md5)
  # echo "Full Secret: ${full_secret}"  # DEBUG
  # Get first 16 characters of above string (first_16_digit)
  first_16_digit=${full_secret::16}
  # echo "Final secret: ${first_16_digit}"  # DEBUG
  # encrypt by staticrypt
  find ${p}/ -type f -name "index.html" -exec /usr/bin/staticrypt {} ${first_16_digit} \;
  # echo it to a file
  # echo ${first_16_digit} # DEBUG
done < ./encryptDirList.tmp

echo "============Generate one password for bk folder"
full_secret=$(echo -n "bk" | openssl enc -aes-256-cbc -pass pass:"${PASSWORD}" -e -base64 -nosalt -md md5)
# Get first 16 characters of above string (first_16_digit)
first_16_digit=${full_secret::16}
# Encrypt all file "index.html" in bk folder with only one password
find ./bk/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} ${first_16_digit} \;

# Steps to encrypt file in secrets folder by using staticrypt (OLD)
# 1. encrypt all files "index.html" inside directory that have prefix "secrets/encrypt-" and posts/encrypt-*
# find ./secrets/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} MNSDneverdie1234! \;
# find ./posts/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} MNSDneverdie1234! \;
# find ./love/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} MNSDneverdie1234! \;
# find ./family/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} MNSDneverdie1234! \;
# find ./cv/encrypt-*/ -type f -name "index.html" -exec /usr/bin/staticrypt {} MNSDneverdie1234! \;
# 2. delete all file index.html inside directory "secrets/encrypt-*/ and posts/encrypt-*/"
rm -rf ./secrets/encrypt-*/index.html
rm -rf ./posts/encrypt-*/index.html
rm -rf ./love/encrypt-*/index.html
rm -rf ./family/encrypt-*/index.html
rm -rf ./cv/encrypt-*/index.html
rm -rf ./bk/encrypt-*/index.html
# 3. rename all file include "_encrypted" to a new name without "_encrypted" (means index_encrypted.html to index.html)
for file in `find -name "*_encrypted*"`; do mv "$file" "${file/_encrypted/}" ; done

echo "Encrypt done!"

echo "============Publish the blog minimo"
# By push all generated resource to reposiotry. Also remove all history commits
git remote set-url origin https://oauth2:$GH_PAT_TOKEN_MINIMO@github.com/hoangmnsd/hoangmnsd.github.io.git
git checkout --orphan latest_branch
git add -A
git commit -am "Push to hoangmnsd/hoangmnsd.github.io.git by [CircleCI]"
git branch -D master
git branch -m master
git push -f origin master

# echo "============Publish the blog the404"
# # Direct back to home
# cd ..
# git clone https://oauth2:$GH_PAT_TOKEN_THE404@github.com/hoangmnsd/hoangmnsd-the404blog-theme.git
# # Remove _index.md because we dont need it in the404 blog
# rm ./content/posts/_index.md
# # Clean and Sync all encrypt-* md files to `private` folder
# rm hoangmnsd-the404blog-theme/content/private/*
# mv ./content/posts/encrypt-*.md hoangmnsd-the404blog-theme/content/private/
# # Clean and Sync the rest md files to `posts` folder
# rm hoangmnsd-the404blog-theme/content/posts/*
# mv ./content/posts/*.md hoangmnsd-the404blog-theme/content/posts/
# # Direct to the404 blog
# cd hoangmnsd-the404blog-theme
# git add .
# git commit -m "Synchronize content from hoangmnsd by [CircleCI]"
# git push -f origin master

