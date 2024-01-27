#!/bin/sh

epm tool eget https://raw.githubusercontent.com/alt-autorepacked/common/v0.2.0/common.sh
. ./common.sh

_package="discord"
_download_url="https://discord.com/api/download?platform=linux&format=deb"

_download() {
    real_download_url=$(epm tool eget --get-latest-url $_download_url)
    epm -y repack "$real_download_url"
}

download_version=$(_get_version_from_download_url)
remote_version=$(_check_version_from_remote)

if [ "$remote_version" != "$download_version" ]; then
    TAG="v$download_version"
    _download
    _add_repo_suffix
    _create_release
    echo "Release created: $TAG"
else
    echo "No new version to release. Current version: $download_version"
fi

rm common.sh
