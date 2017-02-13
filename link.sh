#!/bin/sh

# Create symlinks to the files in dotfiles/ in similarly named locations relative to $HOME.
#
# For example, $SCRIPTDIR/dotfiles/.config/foo/bar will create the following link:
# $ ln -s $SCRIPTDIR/dotfiles/.config/foo/bar.ini $HOME/.config/foo/bar.ini

if [ -z "$HOME" ]; then
    HOME="`getent passwd ${USER} | cut -d: -f6`"
fi
if [ -z "$PWD" ]; then
    PWD=`pwd`
fi

case "$0" in
    /*|~*)
        DOTFILES_DIR="`dirname $0`/dotfiles"
        ;;
    *)
        DOTFILES_DIR="`dirname $PWD/$0`/dotfiles"
        ;;
esac


CANONICAL_DOTFILES_DIR="`cd ${DOTFILES_DIR}; pwd -P`"  # /bin/readlink might not exist

cd "${CANONICAL_DOTFILES_DIR}" && for FILE in `find -type f | sort`; do
    BASENAME="`basename ${FILE}`"
    DIRNAME="`dirname ${FILE} | sed 's/.//'`"
    SRC="${CANONICAL_DOTFILES_DIR}${DIRNAME}/${BASENAME}"
    TARGET_DIR="${HOME}${DIRNAME}"
    LINK="${TARGET_DIR}/${BASENAME}"

    if [ ! -f "${SRC}" ]; then
        echo bad "$FILE", skipping...
        continue
    fi
    if [ -e "${LINK}" ]; then
        echo "${LINK} exists, skipping."
        continue
    fi

    if [ ! -d "${TARGET_DIR}" ]; then
        echo "mkdir -p \"${TARGET_DIR}\""
    fi

    echo "ln -s \"${SRC}\" \"${LINK}\""
done
