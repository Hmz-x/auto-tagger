#!/bin/sh

# Program Data
PROGRAM_NAME="atag.sh"
PROGRAM_AUTHOR="Hamza Kerem Mumcu"
PROGRAM_VERSION="1.0"
PROGRAM_LICENSE="GNU GPLv3"
PROGRAM_HELP=\
"usage: ${PROGRAM_NAME} -a|--audio-input AUDIO_FILE -t|--text-input TEXT_FILE 
[--album ALBUM_NAME] [--artist ARTIST_NAME] [--cover COVER_FILE]"


msg_n_exit()
{
	printf -- "%s. Exitting.\n" "$1"
	exit 1	
}

check_dependencies()
{
	[ -z "$(command -v "ffmpeg")" ] && msg_n_exit "Unable to locate ffmpeg binary"
	[ -z "$(command -v "id3tool")" ] && msg_n_exit "Unable to locate id3tool binary"
}

split_audio()
{
	[ -z "$audio_file" ] && msg_n_exit "No audio file given"
	[ -z "$text_file" ] && msg_n_exit "No text file given"

	tmp_data_file="$(mktemp || msg_n_exit "Unable to create temporary file")"
	file_len=$(wc -l "$text_file" | cut -d ' ' -f 1)

	line_number=1
	while read line; do
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

			#ffmpeg -i "$audio_file" -ss "$prev_timestamp" -t
			echo "$prev_name: $prev_timestamp - $timestamp"
			#if ((i < file_len-1)); then
				#echo "$prev_timestamp - $timestamp"
			#else
				#echo "$prev_timestamp - "
			#fi
		fi

		#echo "timestamp: $timestamp - name: $name"
		((++line_number))
	done < "$text_file"

	echo "$name: $timestamp - EOF"

	rm "$tmp_data_file"
}

parse_opts(){
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
split_audio
