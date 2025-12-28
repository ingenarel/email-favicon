#!/usr/bin/sh

[ -z "$CACHE_PATH" ] && CACHE_PATH="$HOME/.cache/emailfind"
[ -z "$DOMAIN_IGNORE" ] && DOMAIN_IGNORE='(archlinux\.org|patreon)'

if [ "$1" = true ]; then
    _USETOR=true
else
    _USETOR=false
fi

export _USETOR

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

# domainName="$( echo "$2" | sed -n -E 's:\S+@(\S+\.)*([^.]+\.[^.]+)$:\2:p')"
originalDomainName="${2#*@}"
echo "originalDomainName: $originalDomainName" >&2

domainName="$originalDomainName"
echo "domainName: $domainName" >&2

domainLink="https://$domainName/"
echo "domainLink: $domainLink" >&2

icoPath="$CACHE_PATH/$(echo "$originalDomainName" | sha256sum | awk '{print $1}' )"
[ ! -d "$icoPath" ] && mkdir --parents "$icoPath"
echo "icoPath: $icoPath" >&2

# ignore arch manually for now
[ -z "$( find "$icoPath" -type f,l )" ] && echo "$domainName" | grep -v -q -E "$DOMAIN_IGNORE" && {
    while echo "$domainLink" | grep -q -E '[^.]+\.([^.]+\.)+[^.]+$'; do
        toTorOrNotToTor curl --silent --out-null "$domainLink" &&
        break ||
        domainLink="$( echo "$domainLink" | sed -n -E 's:([^/]+//)[^.]+\.(.+):\1\2:p')"
        domainChanged=true
    done
    newIcoPath="${domainLink#https://}"
    newIcoPath="${newIcoPath%/}"
    [ "$domainChanged" = true ] && newIcoPath="$CACHE_PATH/$( echo "$newIcoPath" | sha256sum | awk '{print $1}' )"
    if [ -d "$newIcoPath" ]; then
        rm -rf "$icoPath"
        ln -srf "$newIcoPath" "$icoPath"
    else
        while true; do
            redirURL="$(
            toTorOrNotToTor curl --silent\
                --max-redirs=1\
                --out-null\
                --write-out '%{url_effective}'\
                --follow\
                "$domainLink" |
            grep -oE 'https?://[^/]+/'
        )"
            if ! toTorOrNotToTor wget --quiet "${domainLink}favicon.ico" --directory-prefix "$icoPath"; then
                RFC5988IconLinks="$(toTorOrNotToTor curl --silent "$domainLink" | sed -n -E 's:.*<link\s+rel="icon"\s+type="image/\S+"\s+href="([^"]+)".+:\1:p' )"
                if [ -n "$RFC5988IconLinks" ]; then
                    echo "$RFC5988IconLinks" | while IFS='' read -r line; do
                        toTorOrNotToTor wget --quiet "$domainLink$line" --directory-prefix "$icoPath" && break
                    done
                fi
                # toTorOrNotToTor wget --quiet "$(
                #     toTorOrNotToTor curl --silent --follow "$domainLink" | grep -o -E 'https://\S+\.ico'
                #     )" --directory-prefix "$icoPath" ||
            fi
            file --mime-type "$icoPath"/* | grep -q -E '.*: image/\S+*$' && break || {
                if [ "$redirURL" != "$domainLink" ]; then
                    rm -rf "$icoPath"/*
                    domainLink="$redirURL"
                else
                    break
                fi
            }
        done
        find "$icoPath" -type f,l | while IFS='' read -r line; do
            extensionName="${line##*.}"
            mv "$line" "$(dirname "$line")/favicon.$extensionName"
        done
    fi

}

echo "$icoPath"
