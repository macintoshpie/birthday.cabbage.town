#!/bin/bash

# Configuration
BUCKET_URL="https://cabbagetown.nyc3.digitaloceanspaces.com"
PREFIX="birthday/"
OUTPUT_DIR="./birthday_photos"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Fetching image list from bucket..."

# Fetch the XML listing
xml=$(curl -s "${BUCKET_URL}/?list-type=2&prefix=${PREFIX}")

# Extract all Key elements - handle multiline XML
keys_file=$(mktemp)
echo "$xml" | grep -o '<Key>[^<]*</Key>' | sed 's/<Key>//g; s/<\/Key>//g' > "$keys_file"

key_count=$(wc -l < "$keys_file" | tr -d ' ')
echo "Found $key_count items"

# Download each image
while IFS= read -r key; do
    # Skip empty lines
    if [[ -z "$key" ]]; then
        continue
    fi
    
    # Skip if it's just the directory
    if [[ "$key" == */ ]]; then
        echo "Skipping directory: $key"
        continue
    fi
    
    # Get the filename
    filename=$(basename "$key")
    
    # Check if it's an image file
    if [[ "$filename" =~ \.(jpg|jpeg|png|gif|webp)$ ]]; then
        echo "Downloading: $filename"
        curl -s "${BUCKET_URL}/${key}" -o "${OUTPUT_DIR}/${filename}"
    else
        echo "Skipping non-image: $filename"
    fi
done < "$keys_file"

# Cleanup temp file
rm "$keys_file"

echo "Download complete! Images saved to: $OUTPUT_DIR"