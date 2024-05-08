#!/bin/sh -x

# It will be run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT=discord
PRODUCTCUR=Discord
PRODUCTDIR=/opt/$PRODUCT

. $(dirname $0)/common-chromium-browser.sh

move_to_opt

# fix_chrome_sandbox

########################################################

asar_path="resources/app.asar"
extract_asar_path="$(mktemp -d)"

# try_use_system_electron $BUILDROOT/$PRODUCTDIR/$PRODUCTCUR "." "/"

# electron_version=29
electron_version=$(strings "$BUILDROOT/$PRODUCTDIR/$PRODUCTCUR" | grep "Electron v" | awk '{print $2}' | cut -d'v' -f2 | cut -d'.' -f1)

add_unirequires "electron$electron_version"

asar e "$BUILDROOT/$PRODUCTDIR/$asar_path" "$extract_asar_path"
rm "$BUILDROOT/$PRODUCTDIR/$asar_path"

sed -i "s|process.resourcesPath|'$PRODUCTDIR/resources'|" "$extract_asar_path/app_bootstrap/buildInfo.js"
sed -i -E "s|resourcesPath = _path.+;|resourcesPath = '$PRODUCTDIR/resources';|" "$extract_asar_path/common/paths.js"

asar p "$extract_asar_path" "$BUILDROOT/$PRODUCTDIR/$asar_path"
rm -rf "$extract_asar_path"

########################################################

# add_electron_deps

rm usr/bin/$PRODUCT
add_bin_link_command $PRODUCTCUR $PRODUCTDIR/$PRODUCTCUR
add_bin_link_command $PRODUCT $PRODUCTCUR

rm usr/share/applications/discord.desktop
install_file $PRODUCTDIR/discord.desktop /usr/share/applications/discord.desktop
rm usr/share/pixmaps/discord.png
install_file $PRODUCTDIR/discord.png /usr/share/pixmaps/discord.png

fix_desktop_file /usr/share/discord/Discord $PRODUCT

keep="resources discord.png discord.desktop"

for item in "$BUILDROOT/$PRODUCTDIR"/*; do
    base_item=$(basename "$item")
    if ! echo "$keep" | grep -qw "$base_item"; then
        relative_item="${PRODUCTDIR}/${base_item}"
        if [ -d "$item" ]; then
            remove_dir "$relative_item"
        elif [ -f "$item" ]; then
            remove_file "$relative_item"
        fi
    fi
done

echo "#/bin/sh" create_file 

cat <<EOF |create_file $PRODUCTDIR/$PRODUCTCUR
#!/bin/sh
/usr/bin/electron$electron_version $PRODUCTDIR/$asar_path "\$@"
EOF
chmod 0755 "$BUILDROOT/$PRODUCTDIR/$PRODUCTCUR"
