#!/bin/bash
shopt -q -s nocasematch

INPUTFORMATS=("aac" "flac" "m4a" "mp3" "ogg" "wav" "wma")

[ $# -ne 2 ] && exit 1

INROOT="$(realpath "$1")/"
OUTROOT="$(realpath "$2")/"
export INROOT
export OUTROOT

findfiles() {
	local search=()
	local i
	for i in "${INPUTFORMATS[@]}"; do
		search=("${search[@]}" "-o" "-iname" "*.$i")
	done
	search=('(' "${search[@]:1}" ')')
 	find "$1" -path "${OUTROOT%/}" -prune -o "${search[@]}" -print
}
export -f findfiles

newertomp3() {
	local infile="$1"
	local infileext="${infile##*.}"
	local infilenoext="${infile%.*}"
	local indir="${infile%/*}/"
	local outdir="$OUTROOT/${indir#$INROOT}"
	local outfile="$OUTROOT/${infilenoext#$INROOT}.mp3"
	if [ "$infile" -nt "$outfile" ]; then
		mkdir -p "$outdir"
		if [[ "$infileext" == "mp3" ]]; then
			cp "$infile" "$outfile"
		else
			ffmpeg -nostats -hide_banner -loglevel error -i "$infile" -qscale:a 0 "$outfile"
		fi
	fi
}
export -f newertomp3

run() {
	pushd "$OUTROOT"
	findfiles "$INROOT" \
		| parallel newertomp3 {}

	popd
}
export -f run

run

