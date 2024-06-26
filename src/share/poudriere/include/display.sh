#!/bin/sh
# 
# Copyright (c) 2014 Bryan Drewery <bdrewery@FreeBSD.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

display_setup() {
	[ $# -ge 1 ] || eargs display_setup format [column_sort]
	_DISPLAY_DATA=
	_DISPLAY_FORMAT="$1"
	_DISPLAY_COLUMN_SORT="${3-}"
}

display_add() {
	local arg

	# Add in newline
	[ -n "${_DISPLAY_DATA}" ] && \
	    _DISPLAY_DATA="${_DISPLAY_DATA}
"
	# Quote all arguments
	for arg do
		_DISPLAY_DATA="${_DISPLAY_DATA} '${arg}'"
	done
	return 0
}

display_output() {
	local cnt lengths length format arg flag quiet line n
	local header header_format
	local OPTIND=1

	quiet=0

	while getopts "q" flag; do
		case "${flag}" in
			q)
				quiet=1
				;;
			*)
				err 1 "display_output: Invalid flag"
				;;
		esac
	done

	shift $((OPTIND-1))

	format="${_DISPLAY_FORMAT}"

	# Determine optimal format
	n=0
	while mapfile_read_loop_redir line; do
		n=$((n + 1))
		if [ "${n}" -eq 1 ]; then
			if [ "${quiet}" -eq 1 ]; then
				continue
			fi
			header="${line}"
		fi
		eval "set -- ${line}"
		cnt=0
		for arg in "$@"; do
			hash_get lengths ${cnt} max_length || max_length=0
			stripansi "${arg}" arg
			if [ ${#arg} -gt ${max_length} ]; then
				# Keep the hash var local to this function
				_hash_var_name "lengths" "${cnt}"
				local ${_hash_var_name}
				# Set actual value
				hash_set lengths ${cnt} ${#arg}
			fi
			cnt=$((cnt + 1))
		done
	done <<-EOF
	${_DISPLAY_DATA}
	EOF

	# Set format lengths if format is dynamic width
	case "${format}" in
	*%%*)
		set -- ${format}
		lengths=
		n=0
		for arg in "$@"; do
			# Check if this is a format argument
			case "${arg}" in
			*%*) ;;
			*) continue ;;
			esac
			case ${arg} in
			*%d*)
				hash_get lengths ${n} length
				lengths="${lengths:+${lengths} }${length}"
				;;
			esac
			n=$((n + 1))
		done
		format=$(printf "${format}" ${lengths})
		;;
	esac

	# Show header separately so it is not sorted
	if [ "${quiet}" -eq 0 ]; then
		stripansi "${header}" header
		stripansi "${format}" header_format
		eval "set -- ${header}"
		printf "${header_format}\n" "$@"
	fi

	# Sort as configured in display_setup()
	echo "${_DISPLAY_DATA}" | tail -n +2 | \
	    sort ${_DISPLAY_COLUMN_SORT} | \
	    while mapfile_read_loop_redir line; do
		eval "set -- ${line}"
		printf "${format}\n" "$@"
	done

	unset _DISPLAY_DATA _DISPLAY_FORMAT \
	    _DISPLAY_COLUMN_SORT
}
