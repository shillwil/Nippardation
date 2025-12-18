#!/bin/bash

# This script copies the appropriate GoogleService-Info.plist file based on the build configuration

echo "Running Firebase configuration script..."
echo "Build Configuration: ${CONFIGURATION}"

# Path to the source files
STAGING_FILE="${PROJECT_DIR}/Nippardation/Configuration/GoogleService-Info-Staging.plist"
PROD_FILE="${PROJECT_DIR}/Nippardation/Configuration/GoogleService-Info-Prod.plist"

# Path to the destination in the app bundle
DEST_FILE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Check configuration and copy appropriate file
if [ "${CONFIGURATION}" == "Staging" ] || [ "${CONFIGURATION}" == "Debug-Staging" ]; then
    echo "Copying staging Firebase configuration..."
    cp "${STAGING_FILE}" "${DEST_FILE}"
elif [ "${CONFIGURATION}" == "Production" ] || [ "${CONFIGURATION}" == "Release" ] || [ "${CONFIGURATION}" == "Debug" ]; then
    echo "Copying production Firebase configuration..."
    cp "${PROD_FILE}" "${DEST_FILE}"
else
    echo "Error: Unknown configuration ${CONFIGURATION}"
    exit 1
fi

# Verify the file was copied
if [ -f "${DEST_FILE}" ]; then
    echo "Firebase configuration copied successfully"
else
    echo "Error: Failed to copy Firebase configuration"
    exit 1
fi