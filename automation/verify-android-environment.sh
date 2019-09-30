#!/usr/bin/env bash

# Ensure the build toolchains are set up correctly for android builds.
#
# This file should be used via `./libs/verify-android-environment.sh`.

NDK_VERSION=19
RUST_TARGETS=("aarch64-linux-android" "armv7-linux-androideabi" "i686-linux-android" "x86_64-linux-android")

if [[ ! -f "$(pwd)/.taskcluster.yml" ]]; then
  echo "ERROR: verify-android-environment.sh should be run from the root directory of the repo"
  exit 1
fi

if [[ -z "${ANDROID_HOME}" ]]; then
  echo "Could not find Android SDK:"
  echo 'Please install the Android SDK and then set ANDROID_HOME.'
  exit 1
fi

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "Could not find Android NDK:"
  echo 'Please install the Android NDK and then set ANDROID_NDK_ROOT.'
  exit 1
fi

if [[ -z "${ANDROID_NDK_HOME}" ]]; then
  echo "Environment variable \$ANDROID_NDK_HOME is not set:"
  echo "Please export ANDROID_NDK_HOME=\$ANDROID_NDK_ROOT for compatibility with the android gradle plugin."
  exit 1
elif [[ "${ANDROID_NDK_HOME}" != "${ANDROID_NDK_ROOT}" ]]; then
  echo "Environment variable \$ANDROID_NDK_HOME is different from \$ANDROID_NDK_ROOT."
  echo "Please adjust your environment variables to ensure they are the same."
  exit 1
fi

INSTALLED_NDK_VERSION=$(sed -En -e 's/^Pkg.Revision[ \t]*=[ \t]*([0-9a-f]+).*/\1/p' "${ANDROID_NDK_ROOT}/source.properties")
if [[ "${INSTALLED_NDK_VERSION}" != "${NDK_VERSION}" ]]; then
  echo "Wrong Android NDK version:"
  echo "Expected version ${NDK_VERSION}, got ${INSTALLED_NDK_VERSION}"
  exit 1
fi

rustup target add "${RUST_TARGETS[@]}"

if [[ -z "${ANDROID_NDK_TOOLCHAIN_DIR}" ]]; then
  echo "Could not find Android NDK toolchain directory:"
  echo "1. Create a directory where to set up the toolchains (e.g. ~/.ndk-standalone-toolchains)."
  echo "2. Set ANDROID_NDK_TOOLCHAIN_DIR to this newly created directory."
  exit 1
fi

# Determine the Java command to use to start the JVM.
# Same implementation as gradlew
if [[ -n "$JAVA_HOME" ]] ; then
    if [[ -x "$JAVA_HOME/jre/sh/java" ]] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [[ ! -x "$JAVACMD" ]] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    command -v $JAVACMD >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

JAVA_MAJOR_VERSION=$($JAVACMD -version 2>&1 | sed -E -n 's/.* version "([^.-]*).*"/\1/p' | cut -d' ' -f1)
if [[ "$JAVA_MAJOR_VERSION" -lt 8 ]] ; then
    if [[ "$JAVA_MAJOR_VERSION" -eq 1 ]] ; then
      version=$("$JAVACMD" -version 2>&1 | awk -F '"' '/version/ {print $2}')
      version=$(echo "$version" | awk -F. '{printf("%03d%03d",$1,$2);}')
      if [[ 10#$version -lt 10#001008 ]]; then
          echo "Java version is less than version 8"
          exit
      fi
    else
      echo "ERROR: Incompatible java version"
      exit 1
    fi
fi

echo "Looks good!"
