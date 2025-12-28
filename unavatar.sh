#!/usr/bin/sh

[ -z "$CACHE_PATH" ] && CACHE_PATH="$HOME/.cache/emailfind"

if [ "$1" = true ]; then
    _USETOR=true
else
    _USETOR=false
fi

export _USETOR

icoPath="$CACHE_PATH/$(echo "$2" | sha256sum | awk '{print $1}' )"

toTorOrNotToTor(){
    if [ "$_USETOR" = true ]; then
        echo "using tor to run " "$@" >&2
        torsocks "$@"
    elif [ "$_USETOR" = 'skipthisone' ]; then
        echo "using clear net to run and later switch to tor " "$@" >&2
        "$@"
        _USETOR=true
    else
        echo "using clear net to run " "$@" >&2
        "$@"
    fi
}

[ ! -d "$icoPath" ] && {
    mkdir --parents "$icoPath" 
    #TODO: move to a shared header type file later where it will get sourced in the grabber files

    response="$( toTorOrNotToTor curl --silent "https://unavatar.io/$2?json" )"

    toTorOrNotToTor wget --quiet --directory-prefix "$icoPath" "$(
    echo "$response" |
    grep -vqE 'fallback.png' && echo "$response" |
    grep -oE 'https://[^"]+'
    )"
}

find "$icoPath" -type f,l
