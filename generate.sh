#!/bin/sh

version=$1

if [[ -z "$version" ]]; then
  echo "Usage ./generate.sh <version>"
  echo "Be aware - script will change current git branch!"
  exit 1
fi

git checkout -b $version
mvn versions:set -DnewVersion="${version}-SNAPSHOT" -DgenerateBackupPoms=false
mvn versions:update-property -Dproperty=openhab-core.version -DnewVersion="${version}" -DgenerateBackupPoms=false -N

mvn clean install && mvn clean install

git commit -a -m "Update BOM for openHAB ${version}."