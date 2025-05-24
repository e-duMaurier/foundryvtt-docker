#!/bin/sh

FOUNDRY_APP_DIR="/opt/foundryvtt/resources/app"
FOUNDRY_DATA_DIR="/data/foundryvtt"
FOUNDRY_ZIP_SOURCE="/host_files" # Where the zip is mounted from the host

echo "Checking for Foundry VTT installation in $FOUNDRY_APP_DIR..."

# Check if Foundry VTT is already unpacked in the app directory
if [ ! -f "$FOUNDRY_APP_DIR/main.mjs" ]; then
    echo "Foundry VTT not found in $FOUNDRY_APP_DIR. Attempting to unpack from zip."

    cd "$FOUNDRY_APP_DIR" || { echo "Error: Cannot change to application directory $FOUNDRY_APP_DIR"; exit 1; }

    echo "Copying zip file from $FOUNDRY_ZIP_SOURCE..."
    ZIP_FILE=$(find "$FOUNDRY_ZIP_SOURCE" -maxdepth 1 -type f -name '[f,F]oundry[vtt,VTT]*.zip' -print -quit)

    if [ -z "$ZIP_FILE" ]; then
        echo "Error: No Foundry VTT zip file found in $FOUNDRY_ZIP_SOURCE."
        echo "Please place a 'FoundryVTT-*.zip' file in the directory."
        exit 1
    else
        echo "Found zip file: $ZIP_FILE"
        cp "$ZIP_FILE" . || { echo "Error: Failed to copy zip file."; exit 1; }

        echo "Unzipping into $FOUNDRY_APP_DIR..."
        unzip -o ./*.zip -d unpacked && mv unpacked/* . && rm -rf unpacked ./*.zip || \
        { echo "Error: Failed to unzip or move files."; exit 1; }

        echo "Foundry VTT unpacked successfully."
    fi
else
    echo "Foundry VTT already installed in $FOUNDRY_APP_DIR. Skipping unpack."
fi

echo "Starting Foundry VTT Node.js server..."
cd "$FOUNDRY_APP_DIR" || { echo "Error: Cannot change to application directory $FOUNDRY_APP_DIR"; exit 1; }

node main.mjs --dataPath="$FOUNDRY_DATA_DIR"
