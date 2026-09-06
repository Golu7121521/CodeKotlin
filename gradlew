#!/bin/sh
set -e
DIR="$(cd "$(dirname "$0")" >/dev/null && pwd)"
CLASSPATH="$DIR/gradle/wrapper/gradle-wrapper.jar"
exec java -cp "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
