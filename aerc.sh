#!/usr/bin/sh

rootDir="$( realpath --canonicalize-missing "$0/.." )"

faviconPath="$( "$rootDir/email-to-favicon.sh" "$1" "$AERC_FROM_ADDRESS" )"

pngNames="$( find "$faviconPath" -name '*.png' -printf '%s\t%p\n' )"

[ -z "$pngNames" ] && magick "$faviconPath/favicon."* -background none "$faviconPath/favicon.png"

giveFinalImagePath(){
    {
        [ -n "$pngNames" ] &&
        printf '%s' "$pngNames" ||
        find "$faviconPath"\
            -type f,l\
            -follow\
            -printf '%s\t%p\n'
    } |
    sort --numeric-sort --reverse |
    head -n1 |
    awk -F "\t" '{ print $NF }'
}

notify-send\
    --app-name aerc\
    --icon "$( giveFinalImagePath )"\
    "$AERC_FROM_ADDRESS"\
    "[$AERC_ACCOUNT/$AERC_FOLDER]\n$AERC_SUBJECT"
