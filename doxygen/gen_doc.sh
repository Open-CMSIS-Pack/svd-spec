#!/usr/bin/env bash
# Version: 2.0
# Date: 2022-08-30
# This bash script generates CMSIS-View documentation
#
# Pre-requisites:
# - bash shell (for Windows: install git for Windows)
# - doxygen 1.9.2

set -o pipefail

# Set version of gen pack library
REQUIRED_GEN_PACK_LIB="0.11.1"

DIRNAME=$(dirname $(readlink -f $0))
REQ_DXY_VERSION="1.9.6"

############ DO NOT EDIT BELOW ###########

# Set GEN_PACK_LIB_PATH to use a specific gen-pack library root
# ... instead of bootstrap based on REQUIRED_GEN_PACK_LIB
if [[ -n "${GEN_PACK_LIB_PATH}" ]] && [[ -f "${GEN_PACK_LIB_PATH}/gen-pack" ]]; then
  . "${GEN_PACK_LIB_PATH}/gen-pack"
else
  . <(curl -sL "https://raw.githubusercontent.com/Open-CMSIS-Pack/gen-pack/main/bootstrap")
fi

find_git
find_doxygen "${REQ_DXY_VERSION}"

if [ -z $VERSION ]; then
  VERSION_FULL=$(git_describe "v")
  VERSION=${VERSION_FULL%+*}
fi

pushd "${DIRNAME}" || exit > /dev/null

echo "Generating documentation ..."

sed -e "s/{projectNumber}/${VERSION}/" svd.dxy.in > svd.dxy

git_changelog -f html -p "v" > src/history.txt

echo "\"${UTILITY_DOXYGEN}\" svd.dxy"
"${UTILITY_DOXYGEN}" svd.dxy

if [[ $2 != 0 ]]; then
  mkdir -p "${DIRNAME}/../doc/html/search/"
  cp -f "${DIRNAME}/templates/search.css" "${DIRNAME}/../doc/html/search/"
fi

projectName=$(grep -E "PROJECT_NAME\s+=" svd.dxy | sed -r -e 's/[^"]*"([^"]+)".*/\1/')
projectNumber=$(grep -E "PROJECT_NUMBER\s+=" svd.dxy | sed -r -e 's/[^"]*"([^"]+)".*/\1/')
datetime=$(date -u +'%a %b %e %Y %H:%M:%S')
year=$(date -u +'%Y')
sed -e "s/{datetime}/${datetime}/" "${DIRNAME}/templates/footer.js.in" \
  | sed -e "s/{year}/${year}/" \
  | sed -e "s/{projectName}/${projectName}/" \
  | sed -e "s/{projectNumber}/${VERSION}/" \
  | sed -e "s/{projectNumberFull}/${VERSION_FULL}/" \
  > "${DIRNAME}/../doc/html/footer.js"

popd || exit > /dev/null

exit 0
