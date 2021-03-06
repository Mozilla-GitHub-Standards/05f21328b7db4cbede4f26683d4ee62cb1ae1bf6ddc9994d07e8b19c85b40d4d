#!/usr/bin/env bash

set -eu

BUILD_DIR=`dirname $0`
cd $BUILD_DIR/..

if [ "$GIT_BRANCH" != "" ]; then
  BRANCH=`echo $GIT_BRANCH | sed -e's/^origin\///'`
fi

if [ "$BRANCH" == "" ]; then
  BRANCH=`git symbolic-ref --short HEAD`
fi

if [ "$BRANCH" == "master" ]; then
  echo "Can't release from $BRANCH branch"
  exit 1
fi

echo "Releasing for $BRANCH"

source ./package.rc

echo "Getting phpbb-$PHPBB"
 wget -q -c -O phpbb-release-$PHPBB.tar.gz https://github.com/phpbb/phpbb/archive/release-$PHPBB.tar.gz

echo "svn exporting auth_amo r$AUTH"
 svn -q export --force http://svn.mozilla.org/addons/trunk/site/vendors/phpbb/auth_amo.php -r $AUTH auth_amo-$AUTH.php

echo "svn exporting ca_gen2 theme r$THEME"
 svn -q export --force http://svn.mozilla.org/addons/trunk/site/vendors/phpbb/ca_gen2 ca_gen2-$THEME -r $THEME
 tar zcf ca_gen2-$THEME.tar.gz ca_gen2-$THEME
 rm -rf ca_gen2-$THEME

echo "generating spec file"
cat build/forums.mozilla.org.spec | \
  sed -e "s/%%NAME%%/$BRANCH/g" | \
  sed -e "s/%%PHPBB%%/$PHPBB/g" | \
  sed -e "s/%%THEME%%/$THEME/g" | \
  sed -e "s/%%RELEASE%%/$RELEASE/g" | \
  sed -e "s/%%AUTH%%/$AUTH/g" > \
  $BRANCH.spec

tar zcf $BRANCH.tar.gz $BRANCH.spec ca_gen2-$THEME.tar.gz phpbb-release-$PHPBB.tar.gz auth_amo-$AUTH.php

RPMBUILD="rpmbuild -ta $BRANCH.tar.gz"

echo "Building RPM"
if [ "$*" != "" ]; then
  $RPMBUILD "$*"
else
  $RPMBUILD
fi

rm ca_gen2-$THEME.tar.gz phpbb-release-$PHPBB.tar.gz auth_amo-$AUTH.php $BRANCH.spec

mv $HOME/rpmbuild/SRPMS/$BRANCH*.rpm . 
mv $HOME/rpmbuild/RPMS/noarch/$BRANCH*.rpm .


