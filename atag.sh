#!/bin/sh

# Program Data
program_name="atag.sh"
program_author="Hamza Kerem Mumcu"
program_version="1.0"

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

parse_opts(){
	# Parse and evaluate each option one by one 
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-a|--audio-input) 
				audio_file="$2"
				[ -r "$audio_file" ] || msg_n_exit "Unable to read audio file $audio_file"
				shift;;
			-t|--text-input) 
				text_file="$2" 
				[ -r "$text_file" ] || msg_n_exit "Unable to read text file $text_file"
				shift;;
			 *) msg_n_exit "Unknown option '$1'";;
		esac
		shift
	done
}

check_dependencies
parse_opts "$@"
