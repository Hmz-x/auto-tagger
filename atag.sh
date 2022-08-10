#!/bin/sh

# Program Data
PROGRAM_NAME="atag.sh"
PROGRAM_AUTHOR="Hamza Kerem Mumcu"
PROGRAM_VERSION="1.0"
PROGRAM_LICENSE="GNU GPLv3"
PROGRAM_HELP=\
"usage: ${PROGRAM_NAME} -a|--audio-input AUDIO_FILE -t|--text-input TEXT_FILE 
[--album ALBUM_NAME] [--artist ARTIST_NAME] [--year YEAR] [--cover COVER_FILE]"

msg_n_exit()
{
	printf -- "%s. Exitting.\n" "$1"
	exit 1	
}

check_dependencies()
{
	[ -z "$(command -v "ffmpeg")" ] && msg_n_exit "Unable to locate ffmpeg binary"
	[ -z "$(command -v "eyeD3")" ] && msg_n_exit "Unable to locate eyeD3 binary"
}

split_n_tag_track()
{
	track_number=$1
	track_name="$2"
	starting_timestamp="$3"
	ending_timestamp="$4"

	out_file="${track_name}.${audio_extension}"
	
	# Split track
	if [ -n "$ending_timestamp" ]; then
		ffmpeg -vn -y -nostdin -i "$audio_file" -ss "$starting_timestamp" -to \
			"$ending_timestamp" "$out_file"
	else
		ffmpeg -vn -y -nostdin -i "$audio_file" -ss "$starting_timestamp" "$out_file"
	fi
	
	# Tag track
	eyeD3 -Q --remove-all --title "$track_name" --track $track_number "$out_file"
	[ -n "$album_name" ] && id3tool -Q --album "$album_name" "$out_file"
	[ -n "$artist_name" ] && id3tool -Q --artist "$artist_name" "$out_file"
	[ -n "$year_data" ] && id3tool -Q --release-year $year_data "$out_file"
}

split_audio_loop()
{
	[ -z "$audio_file" ] && msg_n_exit "No audio file given"
	[ -z "$text_file" ] && msg_n_exit "No text file given"

	tmp_data_file="$(mktemp || msg_n_exit "Unable to create temporary file")"
	file_len=$(wc -l "$text_file" | cut -d ' ' -f 1)

	line_number=1
	while read -r line; do
		#time_stamp="$(echo "$line" | grep -Ewo \
			#"([0-9])*([0-9]:)*([0-6])*[0-9]:[0-6][0-9]")"

		#name="$(echo "$line" | tr -s "$time_stamp" " ")"
		# Remove proceeding and trailing whitespace
		
		timestamp="0:$((line_number-1))0"
		name="song_${line_number}"

		echo "$timestamp $name" >> "$tmp_data_file"
		
		if ((line_number > 1)); then
			prev_line="$(cat "$tmp_data_file" | awk "NR==$((line_number-1))")"
			prev_timestamp="$(echo "$prev_line" | cut -d ' ' -f 1)"
			prev_name="$(echo "$prev_line" | cut -d ' ' -f 2-)"

			#echo "$prev_name: $prev_timestamp - $timestamp"
			split_n_tag_track $((line_number-1)) "$prev_name" "$prev_timestamp" "$timestamp"
		fi

		((++line_number))
	done < "$text_file"

	#echo "$name: $timestamp - EOF"
	split_n_tag_track $((line_number-1)) "$name" "$timestamp"

	rm "$tmp_data_file"
}

parse_opts(){
	# Default values
	audio_extension="mp3"

	# Parse and evaluate each option one by one 
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h|--help)
				printf -- "%s\n" "$PROGRAM_HELP"
				exit 0
				shift;;
			-a|--audio-input) 
				audio_file="$2"
				[ -r "$audio_file" ] || msg_n_exit "Unable to read audio file $audio_file"
				shift;;
			-t|--text-input) 
				text_file="$2" 
				[ -r "$text_file" ] || msg_n_exit "Unable to read text file $text_file"
				shift;;
			--album)
				album_name="$2" 
				[ -z "$album_name" ] && msg_n_exit "No album name given"
				shift;;
			--artist)
				artist_name="$2" 
				[ -z "$artist_name" ] && msg_n_exit "No artist name given"
				shift;;
			--year)
				year_data="$2" 
				[ -z "$year_data" ] && msg_n_exit "No year data given"
				shift;;
			--cover)
				cover_file="$2"
				[ -r "$text_file" ] || msg_n_exit "Unable to read cover file $cover_file"
				shift;;
			 *) msg_n_exit "Unknown option '$1'";;
		esac
		shift
	done
}

check_dependencies
parse_opts "$@"
split_audio_loop
