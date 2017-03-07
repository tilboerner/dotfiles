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


function error() {
	(>&2 echo $@)
}

function samefiles() {
	cmp "$1" "$2" > /dev/null
	return $?
}

function symlink() {
	ORIGINAL="$1"
	LINK="$2"
	echo  link "${LINK}" '-->' "${SRC}"
	ln -s "${SRC}" "${LINK}"
}

function tmpdir() {
	if [ -z "$TMPDIR" ]; then
		TMPDIR="`mktemp -d --suffix='-dotfiles'`"
	fi
	echo "$TMPDIR"
}

function merge() {
	OURS="$1"
	TARGET="$2"

	if samefiles "$OURS" "$TARGET"; then
		return 0
	fi

	TMPDIR="`tmpdir`"
	mkdir -p "${TMPDIR}`dirname \"${TARGET}\"`"
	THEIRS="${TMPDIR}${TARGET}"
	cp "$TARGET" "$THEIRS"
	chmod -w "$THEIRS"

	while [ ! -x "$MERGE_TOOL" ]; do
		if [ -n "$MERGE_TOOL" ]; then
			echo "$MERGE_TOOL" not executable!
		fi
		echo -n "Enter merge command (e.g. diffuse) or [q]uit: "
		read cmd
		case "$cmd" in
			q|quit) exit;;
			*) MERGE_TOOL="`which \"$cmd\"`";;
		esac
	done

	$MERGE_TOOL "$OURS" "$TARGET" "$THEIRS"

	if [ $? -ne 0 ]; then
		error "$MERGE_TOOL" exited with error status
		return 1
	elif samefiles "$TARGET" "$THEIRS"; then
		echo -n "Target did not change. Was the merge successful? [yN] "
		read answer
		test "$answer" = "y"
		return $?
	fi
	return 0
}

cd "${CANONICAL_DOTFILES_DIR}"
for FILE in `find -type f | sort`; do
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
		echo
		echo -n "${LINK} exists. [s]kip, [m]erge, [!r]emove, [h]elp, [q]uit? "
		read answer
		case "$answer" in
			s|S) continue;;
			q|Q) exit;;
			'!r') rm "$LINK" && echo "deleted $LINK";;
			m|M)
				if ! merge "$SRC" "$LINK"; then
					error "Merge failed. Aborting."
					exit 1
				else
					echo "Using $LINK"
					continue
				fi
				;;
			h|H|?)
				cat <<-EOF
				s   Skip.
				        Keeps the existing file and moves to the next dotfile.
				m   Merge.
				        Opens an editor of your choice with DOTFILE, EXISTING, EXISTING_COPY,
				        giving you the chance to edit the first two. The results will be kept
				        in the state you leave them.
				!r  Remove.
				        Replaces the existing file with a symlink to the dotfile.
				        Yes, type an '!' before the 'r', so we know you really mean it.
				h   Help
				        Shows this text and quits.
				q   Quit
				        Just quits right then.
				EOF
				exit
				;;
			*|'')
				if [ -n "$answer" ]; then
					echo -n "Unknown choice: ${answer}. "
				fi
				echo "Skipping."
				continue
				;;
		esac
	fi
	echo "$TARGET_DIR $LINK"
	if [ ! -d "${TARGET_DIR}" ]; then
		echo "mkdir -p \"${TARGET_DIR}\""
		mkdir -p "${TARGET_DIR}"
	fi

	symlink "${SRC}" "${LINK}"
done
