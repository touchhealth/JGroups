#!/bin/bash

set -euo pipefail

tag_file="release-in-progress"
version_file="conf/JGROUPS_VERSION.properties"

create_commit() {
    sed -i -E "s/^jgroups.version=.+$/jgroups.version=$1/" "$version_file"
    mvn versions:set -DnewVersion="$1" -DgenerateBackupPoms=false
    git add "$version_file" pom.xml
    git commit -q -m "Changed version to $1"
}

prepare() {
    local version="$(sed -n -E 's/^jgroups.version=(.+)-SNAPSHOT$/\1/p' "$version_file")"
    local v=( ${version//./ } )
    local release_version="${v[0]}.${v[1]}.${v[2]}.touch"
    local snapshot_version="${v[0]}.${v[1]}.$(( ${v[2]} + 1 ))-SNAPSHOT"
    local tag="JGroups-$release_version"

    create_commit "$release_version"
    git tag "$tag"
    create_commit "$snapshot_version"
    echo "$tag" > "$tag_file"

    echo
    echo "Done!"
}

deploy() {
    local tag="$(cat "$tag_file")"

    local props
    readarray -t props < repositories.properties

    git checkout "$tag"
    mvn clean deploy -Dlog4j2.disable.jmx "${props[@]/#/-D}"
    rm "$tag_file"

    echo
    echo "Done!"
}

case "${1:-}" in
    prepare)
        prepare
        ;;
    deploy)
        deploy
        ;;
    *)
        echo "usage: bin/release_to_custom_repo.sh [prepare|deploy]"
        exit 1
        ;;
esac
