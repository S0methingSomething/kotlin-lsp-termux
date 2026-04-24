#!/system/bin/sh
set -eu

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
GLIBC_PREFIX="${GLIBC_PREFIX:-$PREFIX/glibc}"
LD_SO="$GLIBC_PREFIX/lib/ld-linux-aarch64.so.1"
JAVA_BIN="$DIR/jre/bin/java"
TMP_DIR="${TMPDIR:-$PREFIX/tmp}"

if [ ! -d "$DIR/lib" ]; then
  echo >&2 "Expected lib directory at $DIR/lib"
  exit 1
fi

if [ ! -f "$JAVA_BIN" ]; then
  echo >&2 "Bundled JRE not found at $JAVA_BIN"
  exit 1
fi

if [ ! -f "$LD_SO" ]; then
  echo >&2 "glibc loader not found at $LD_SO"
  echo >&2 "Install the Termux glibc package set before launching Kotlin LSP."
  exit 1
fi

mkdir -p "$TMP_DIR"

mode_set=0
for arg in "$@"; do
  case "$arg" in
    --stdio|--client|--socket|--socket=*)
      mode_set=1
      ;;
  esac
done

if [ "$mode_set" -eq 0 ]; then
  set -- --stdio "$@"
fi

unset LD_PRELOAD
export PATH="$GLIBC_PREFIX/bin:$PATH"

exec "$LD_SO" "$JAVA_BIN" \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.lang.ref=ALL-UNNAMED \
  --add-opens java.base/java.lang.reflect=ALL-UNNAMED \
  --add-opens java.base/java.net=ALL-UNNAMED \
  --add-opens java.base/java.nio=ALL-UNNAMED \
  --add-opens java.base/java.nio.charset=ALL-UNNAMED \
  --add-opens java.base/java.text=ALL-UNNAMED \
  --add-opens java.base/java.time=ALL-UNNAMED \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.util.concurrent=ALL-UNNAMED \
  --add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED \
  --add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED \
  --add-opens java.base/jdk.internal.ref=ALL-UNNAMED \
  --add-opens java.base/jdk.internal.vm=ALL-UNNAMED \
  --add-opens java.base/sun.net.dns=ALL-UNNAMED \
  --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
  --add-opens java.base/sun.nio.fs=ALL-UNNAMED \
  --add-opens java.base/sun.security.ssl=ALL-UNNAMED \
  --add-opens java.base/sun.security.util=ALL-UNNAMED \
  --add-opens java.desktop/com.sun.java.swing=ALL-UNNAMED \
  --add-opens java.desktop/com.sun.java.swing.plaf.gtk=ALL-UNNAMED \
  --add-opens java.desktop/java.awt=ALL-UNNAMED \
  --add-opens java.desktop/java.awt.dnd.peer=ALL-UNNAMED \
  --add-opens java.desktop/java.awt.event=ALL-UNNAMED \
  --add-opens java.desktop/java.awt.font=ALL-UNNAMED \
  --add-opens java.desktop/java.awt.image=ALL-UNNAMED \
  --add-opens java.desktop/java.awt.peer=ALL-UNNAMED \
  --add-opens java.desktop/javax.swing=ALL-UNNAMED \
  --add-opens java.desktop/javax.swing.plaf.basic=ALL-UNNAMED \
  --add-opens java.desktop/javax.swing.text=ALL-UNNAMED \
  --add-opens java.desktop/javax.swing.text.html=ALL-UNNAMED \
  --add-opens java.desktop/sun.awt=ALL-UNNAMED \
  --add-opens java.desktop/sun.awt.X11=ALL-UNNAMED \
  --add-opens java.desktop/sun.awt.datatransfer=ALL-UNNAMED \
  --add-opens java.desktop/sun.awt.image=ALL-UNNAMED \
  --add-opens java.desktop/sun.font=ALL-UNNAMED \
  --add-opens java.desktop/sun.java2d=ALL-UNNAMED \
  --add-opens java.desktop/sun.swing=ALL-UNNAMED \
  --add-opens java.management/sun.management=ALL-UNNAMED \
  --add-opens jdk.attach/sun.tools.attach=ALL-UNNAMED \
  --add-opens jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
  --add-opens jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED \
  --add-opens jdk.jdi/com.sun.tools.jdi=ALL-UNNAMED \
  --enable-native-access=ALL-UNNAMED \
  -Djdk.lang.Process.launchMechanism=FORK \
  -Djava.io.tmpdir="$TMP_DIR" \
  -Didea.log.console=false \
  -Djava.awt.headless=true \
  -Djava.system.class.loader=com.intellij.util.lang.PathClassLoader \
  -Xlog:cds=off \
  -cp "$DIR/lib/*" com.jetbrains.ls.kotlinLsp.KotlinLspServerKt \
  "$@"
