#!/usr/bin/sh

rootDir="$( realpath --canonicalize-missing "$0/.." )"

# before someone yaps, every personal mail here is public data already
for mail in\
    'bingo@patreon.com'\
    'ingenarelitems@gmail.com'\
    'mailer-daemon@googlemail.com'\
    'no-reply@accounts.google.com'\
    'no-reply@disroot.org'\
    'noreply@steampowered.com'\
    'notifications@github.com'\
    'outgoing@sr.ht'\
    'Pandora-Behaviour-Engine-Plus@noreply.github.com'\
    'pitastrudl@archlinux.org'\
    'platform-support@patreon.zendesk.com'\
    'shit@pm.me'\

    do
    export AERC_FROM_ADDRESS="$mail"
    export AERC_ACCOUNT="neovim"
    export AERC_FOLDER="is"
    export AERC_SUBJECT="the best text editor"
    "$rootDir/aerc.sh" true 2>/dev/null;
done
