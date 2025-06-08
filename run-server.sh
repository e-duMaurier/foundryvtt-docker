#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.
# set -x # Uncomment for extremely verbose debugging (shows every command)

FOUNDRY_APP_DIR="/opt/foundryvtt/resources/app"
FOUNDRY_DATA_DIR="/data/foundryvtt"
FOUNDRY_ZIP_SOURCE="/host_files"
LAST_ZIP_HASH_FILE="$FOUNDRY_APP_DIR/.last_zip_hash"

echo "Checking for Foundry VTT installation or update..."

# Find the Foundry VTT zip file in the source directory
ZIP_FILE=$(find "$FOUNDRY_ZIP_SOURCE" -maxdepth 1 -type f -name '[f,F]oundry[vtt,VTT]*.zip' -print -quit)

if [ -z "$ZIP_FILE" ]; then
    echo "Error: No Foundry VTT zip file found in $FOUNDRY_ZIP_SOURCE."
    echo "Please place a 'FoundryVTT-*.zip' file directly in the mounted directory on your host."
    exit 1
fi

CURRENT_ZIP_HASH=$(md5sum "$ZIP_FILE" | awk '{print $1}')

LAST_STORED_HASH=""
if [ -f "$LAST_ZIP_HASH_FILE" ]; then
    LAST_STORED_HASH=$(cat "$LAST_ZIP_HASH_FILE")
fi

# Determine the actual path to main.mjs based on potential Foundry VTT versions
FOUNDRY_MAIN_MJS_PATH=""
FOUNDRY_NODE_APP_ROOT=""

# Check if main.mjs exists directly in the app directory (Foundry VTT v13+)
if [ -f "$FOUNDRY_APP_DIR/main.mjs" ]; then
    FOUNDRY_MAIN_MJS_PATH="$FOUNDRY_APP_DIR/main.mjs"
    FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR"
# Check if main.mjs exists nested under resources/app (Foundry VTT v12-)
elif [ -f "$FOUNDRY_APP_DIR/resources/app/main.mjs" ]; then
    FOUNDRY_MAIN_MJS_PATH="$FOUNDRY_APP_DIR/resources/app/main.mjs"
    FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR/resources/app"
fi

# Determine if unpack is needed
UNZIP_NEEDED="no"
if [ -z "$FOUNDRY_MAIN_MJS_PATH" ]; then # No main.mjs found in either expected location
    echo "Foundry VTT app (main.mjs) not found in expected locations. File needs to be unzipped for fresh install."
    UNZIP_NEEDED="yes"
elif [ "$CURRENT_ZIP_HASH" != "$LAST_STORED_HASH" ]; then
    echo "Foundry VTT zip hash has changed ($LAST_STORED_HASH -> $CURRENT_ZIP_HASH). Unzip is needed."
    UNZIP_NEEDED="yes"
else
    echo "Foundry VTT app found and zip file hash matches previous version. Skipping unzip."
fi

if [ "$UNZIP_NEEDED" = "yes" ]; then
    echo "Performing unzip/update..."

    # Ensure we are in the correct directory for unpacking
    cd "$FOUNDRY_APP_DIR" || { echo "Error: Cannot change to application directory $FOUNDRY_APP_DIR"; exit 1; }

    # Clean the existing app directory contents thoroughly
    echo "Clearing existing app directory contents..."
    # Removed shopt -s nullglob and shopt -u nullglob as 'shopt' is not available in ash (Alpine's default shell)
    rm -rf "$FOUNDRY_APP_DIR"/*

    echo "Copying zip file '$ZIP_FILE' to temporary location for unzipping..."
    cp "$ZIP_FILE" ./temp_foundry_zip.zip || { echo "Error: Failed to copy zip file. Check permissions on $FOUNDRY_APP_DIR."; exit 1; }

    echo "Unzipping contents into $FOUNDRY_APP_DIR..."
    unzip -o ./temp_foundry_zip.zip || \
    { echo "Error: Failed to unzip. Ensure 'unzip' is installed and zip file is valid."; exit 1; }

    rm -f ./temp_foundry_zip.zip || { echo "Warning: Failed to clean up temporary zip file."; }

    echo "Foundry VTT unzipped successfully."

    # After unpacking, redetermine the correct app root based on the newly extracted files
    FOUNDRY_MAIN_MJS_PATH=""
    FOUNDRY_NODE_APP_ROOT=""
    if [ -f "$FOUNDRY_APP_DIR/main.mjs" ]; then
        FOUNDRY_MAIN_MJS_PATH="$FOUNDRY_APP_DIR/main.mjs"
        FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR"
    elif [ -f "$FOUNDRY_APP_DIR/resources/app/main.mjs" ]; then
        FOUNDRY_MAIN_MJS_PATH="$FOUNDRY_APP_DIR/resources/app/main.mjs"
        FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR/resources/app"
    fi

    # If still not found after unpack, something went wrong
    if [ -z "$FOUNDRY_NODE_APP_ROOT" ]; then
        echo "Critical Error: main.mjs not found in any expected location after unpacking!"
        ls -lah "$FOUNDRY_APP_DIR" # Show what was actually unpacked
        exit 1
    fi

    echo "$CURRENT_ZIP_HASH" > "$LAST_ZIP_HASH_FILE" || { echo "Warning: Could not write hash file."; }
fi

# Check if FOUNDRY_NODE_APP_ROOT was determined from a previous successful run
if [ -z "$FOUNDRY_NODE_APP_ROOT" ]; then
    # This block is for cases where UNZIP_NEEDED was 'no' (i.e., Foundry already installed)
    # and we need to determine the correct root path from the existing files.
    if [ -f "$FOUNDRY_APP_DIR/main.mjs" ]; then
        FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR"
    elif [ -f "$FOUNDRY_APP_DIR/resources/app/main.mjs" ]; then
        FOUNDRY_NODE_APP_ROOT="$FOUNDRY_APP_DIR/resources/app"
    else
        echo "Error: Existing Foundry VTT installation found, but main.mjs could not be located in expected paths."
        exit 1
    fi
fi


# --- DEBUG INFO (Keep, remove once confirmed working consistently) ---
echo "--- DEBUG INFO ---"
echo "Found Foundry VTT app root at: $FOUNDRY_NODE_APP_ROOT"
echo "Contents of $FOUNDRY_NODE_APP_ROOT:"
ls -lah "$FOUNDRY_NODE_APP_ROOT" || echo "ls command failed for $FOUNDRY_NODE_APP_ROOT."
echo "Attempting to cat $FOUNDRY_MAIN_MJS_PATH (if found):"
cat "$FOUNDRY_MAIN_MJS_PATH" 2>/dev/null || echo "main.mjs not found or unreadable by cat."
echo "--- END DEBUG INFO ---"

# Keep container alive for manual inspection if needed (remove for production)
# echo "Pausing container for manual inspection (sleeping for 1 hour)..."
# sleep 3600

echo "Starting Foundry VTT Node.js server from $FOUNDRY_NODE_APP_ROOT..."
cd "$FOUNDRY_NODE_APP_ROOT" || { echo "Error: Cannot change to actual application root $FOUNDRY_NODE_APP_ROOT"; exit 1; }

node main.mjs --dataPath="$FOUNDRY_DATA_DIR"
