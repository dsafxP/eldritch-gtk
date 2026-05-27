#!/usr/bin/env bash
set -euo pipefail

# Configuration
PREFIX="oomox-"
THEMES_DIR="${HOME}/.cache/.themes"
SCRIPT_DIR="$(pwd)"
NEW_COMMENT="A theme for the Ancient Ones!"

# Sanity checks
if [[ ! -d "$THEMES_DIR" ]]; then
    echo "Error: themes directory '$THEMES_DIR' does not exist." >&2
    exit 1
fi

if [[ ! -f "${SCRIPT_DIR}/assets/thumbnail.png" ]]; then
    echo "Error: '${SCRIPT_DIR}/assets/thumbnail.png' not found in working directory." >&2
    exit 1
fi

# Process each theme folder
shopt -s nullglob
processed=0

for theme_path in "${THEMES_DIR}"/*/; do
    theme_path="${theme_path%/}"        # strip trailing slash
    folder_name="$(basename "$theme_path")"

    # Strip prefix if present, otherwise skip
    if [[ "$folder_name" != "${PREFIX}"* ]]; then
        echo "Skipping '${folder_name}' (no '${PREFIX}' prefix)."
        continue
    fi

    new_name="${folder_name#"${PREFIX}"}"
    new_path="${THEMES_DIR}/${new_name}"

    echo "──────────────────────────────────────────"
    echo "Processing: ${folder_name}  →  ${new_name}"

    # 1. Rename folder (remove prefix)
    mv -- "$theme_path" "$new_path"
    theme_path="$new_path"

    # 2. Remove unwanted files
    echo "  Removing assets/all-assets.*"
    rm -f "${theme_path}"/assets/all-assets.*

    echo "  Removing assets/*.sh"
    rm -f "${theme_path}"/assets/*.sh

    echo "  Removing gtk-3.0/assets/*.sh"
    rm -f "${theme_path}"/gtk-3.0/assets/*.sh

    echo "  Removing gtk-3.0/assets/all-assets.*"
    rm -f "${theme_path}"/gtk-3.0/assets/all-assets.*

    # 3. Copy thumbnail into cinnamon/
    if [[ -d "${theme_path}/cinnamon" ]]; then
        echo "  Copying thumbnail → cinnamon/thumbnail.png"
        cp -- "${SCRIPT_DIR}/assets/thumbnail.png" "${theme_path}/cinnamon/thumbnail.png"
    else
        echo "  Warning: '${theme_path}/cinnamon' not found; skipping thumbnail copy."
    fi

    # 4. Edit index.theme
    index_file="${theme_path}/index.theme"
    if [[ -f "$index_file" ]]; then
        echo "  Patching index.theme"

        # Remove all occurrences of the prefix
        sed -i "s/${PREFIX}//g" "$index_file"

        # Replace the Comment= line with the new description
        sed -i "s/^Comment=.*/Comment=${NEW_COMMENT}/" "$index_file"
    else
        echo "  Warning: index.theme not found; skipping patch."
    fi

    # 5. Archive with apack
    archive="${THEMES_DIR}/${new_name}.tar.gz"
    echo "  Archiving → ${archive}"
    ( cd "${THEMES_DIR}" && apack "${archive}" "${new_name}" )

    echo "  Done: ${new_name}.tar.gz"
    (( processed++ )) || true
done

echo "══════════════════════════════════════════"
echo "Finished. Processed ${processed} theme(s)."