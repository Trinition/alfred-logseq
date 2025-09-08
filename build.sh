#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
SRC_DIR="src"
TARGET_DIR="target"
BUILD_DIR="build"
WORKFLOW_NAME="Logseq.alfredworkflow"
UNPACKED_DIR="$BUILD_DIR/unpacked"

# --- Build Process ---

# 1. Clean up and create directories
echo "Cleaning up previous builds..."
rm -rf "$BUILD_DIR"
rm -f "$TARGET_DIR/$WORKFLOW_NAME"
mkdir -p "$TARGET_DIR"
mkdir -p "$UNPACKED_DIR"

# 2. Copy all source files to the temporary unpacked directory
echo "Copying source files..."
rsync -a "$SRC_DIR/" "$UNPACKED_DIR/"

# 3. Inject the script content into info.plist
echo "Injecting script into info.plist..."
sed -i.bak -e '/##SET_KEY_SCRIPT##/r '"$UNPACKED_DIR/set_key.sh"'' -e '/##SET_KEY_SCRIPT##/d' "$UNPACKED_DIR/info.plist"
rm "$UNPACKED_DIR/info.plist.bak"

sed -i.bak -e '/##MAIN_LOGIC_SCRIPT##/r '"$UNPACKED_DIR/main_logic.sh"'' -e '/##MAIN_LOGIC_SCRIPT##/d' "$UNPACKED_DIR/info.plist"
rm "$UNPACKED_DIR/info.plist.bak"

rm "$UNPACKED_DIR/set_key.sh"
rm "$UNPACKED_DIR/main_logic.sh"

# 4. Zip the contents of the unpacked directory
echo "Zipping the final workflow..."
(
  cd "$UNPACKED_DIR"
  zip -r "../../$TARGET_DIR/$WORKFLOW_NAME" . -x "*.DS_Store"
)

echo "Build complete: $TARGET_DIR/$WORKFLOW_NAME"

# 5. (Optional) Install the workflow
if [ "$1" == "install" ]; then
  echo "Opening workflow to install in Alfred..."
  open "$TARGET_DIR/$WORKFLOW_NAME"
fi
