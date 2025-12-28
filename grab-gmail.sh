#!/usr/bin/sh
[ -z "$CACHE_PATH" ] && CACHE_PATH="$HOME/.cache/emailfind"

if [ "$1" = true ]; then
    _USETOR=true
else
    _USETOR=false
fi

export _USETOR

curlWrapper(){
    if [ "$_USETOR" = true ]; then
        echo "using tor to run curl" "$@" >&2
        curl -silent --socks5-hostname localhost:9050 "$@"
    else
        echo "using clear net to run " "$@" >&2
        curl --silent "$@"
    fi
}


wgetWrapper(){
    if [ "$_USETOR" = true ]; then
        echo "using tor to run wget" "$@" >&2
        torsocks wget --quiet "$@"
    else
        echo "using clear net to run wget" "$@" >&2
        wget --quiet "$@"
    fi
}

emailName="${2%@*}"

icoPath="$CACHE_PATH/$(echo "$2" | sha256sum | awk '{print $1}' )"
[ ! -d "$icoPath" ] && mkdir --parents "$icoPath"

# this is skid behaviour but i need to go to these lengths because gmail is a cuck that won't create a public api that
# should fucking public because if both idiots use gmail in the web they're gonna see each other's profile image anyway

imageNames="$(find "$icoPath" -type f,l)"

if [ -z "$imageNames" ]; then
    wgetWrapper --directory-prefix "$icoPath" "$(
    curlWrapper "https://gmail-osint.activetk.jp/$emailName" |
    grep -oE 'https://lh3.googleusercontent.com/\S+'
)"
    find "$icoPath" -type f,l
else
    echo "$imageNames"
fi
