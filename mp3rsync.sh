#!/bin/bash
shopt -q -s nocasematch

#INPUTFORMATS=("aac" "flac" "m4a" "mp3" "ogg" "wav" "wma")

[ $# -ne 2 ] && exit 1

INROOT="$(realpath "$1")/"
OUTROOT="$(realpath "$2")/"
export INROOT
export OUTROOT

getinputformats() {
	(
		echo "${INPUTFORMATS[@]}"
		ffmpeg -nostats -hide_banner -loglevel error -decoders \
			| grep -e '^ A' | cut -f3 -d' ' | cut -f1 -d'_'
		ffmpeg -nostats -hide_banner -loglevel error -formats \
			| grep -i -E '(audio|flac|musepack|ogg|pcm|sound|speech|voice|wavpack)' \
			| grep -v -i -E '(video)' \
			| sed -n -e 's,^ D[[:alnum:]]*  *\([^ ]*\) .*,\1,p'
		ffmpeg -nostats -hide_banner -loglevel error -formats \
			| grep -i -E '(audio|flac|musepack|ogg|pcm|sound|speech|voice|wavpack)' \
			| grep -v -i -E '(video)' \
			| sed -n -e 's,^ D[[:alnum:]]*  *\([^ ]*\) .*,\1,p' \
			| parallel ffmpeg -v 0 -h demuxer={} \
			| sed -n -e '/extensions/{s#[^:]*: *##;s#[,.]# #g;p}'
	) | tr '[[:space:]]' '\n' | sort -u
}

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
			cp "$infile" "$outfile" \
				&& echo "$infile	$outfile	COPIED"
		else
			ffmpeg -nostats -hide_banner -loglevel error -i "$infile" -qscale:a 0 "$outfile" \
				&& echo "$infile	$outfile	COPIED"
		fi
	else
		echo "$infile	$outfile	UP-TO-DATE"
	fi
}
export -f newertomp3

run() {
	INPUTFORMATS=( $(getinputformats) )
	pushd "$OUTROOT"
	findfiles "$INROOT" \
		| parallel newertomp3 {}

	popd
}
export -f run

run

