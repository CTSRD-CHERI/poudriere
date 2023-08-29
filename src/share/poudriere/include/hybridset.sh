#!/bin/sh
#
# Copyright (c) 2023 Konrad Witaszczyk
#
# This software was developed by the University of Cambridge Department of
# Computer Science and Technology with support from Innovate UK project 105694,
# "Digital Security by Design (DSbD) Technology Platform Prototype".
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
#

_datadir_exists() {
	if [ ! -d "${MASTER_DATADIR}" ]; then
		err 1 "${1}: '${MASTER_DATADIR_ABS}' does not exist"
	fi
}

hybridset_init() {
	mkdir -p "${MASTER_DATADIR}/hybridset"
}

hybridset_exists() {
	_datadir_exists hybridset_exists
	[ -d "${MASTER_DATADIR_ABS}/hybridset" ]
}

hybridset_contains() {
	_datadir_exists hybridset_contains
	[ $# -eq 2 ] || eargs hybridset_contains pkgname dep_pkgname
	local pkgname="$1"
	local dep_pkgname="$2"
	local pkg_dir_name

	[ -d "${MASTER_DATADIR_ABS}/hybridset/${pkgname}/${dep_pkgname}" ]
}

hybridset_add() {
	_datadir_exists hybridset_add
	[ $# -eq 2 ] || eargs hybridset_add pkgname dep_pkgname
	local pkgname="$1"
	local dep_pkgname="$2"

	mkdir -p "${MASTER_DATADIR_ABS}/hybridset/${pkgname}/${dep_pkgname}"
}

hybridset_list() {
	_datadir_exists hybridset_list
	[ $# -eq 0 ] || eargs hybridset_list

	(cd "${MASTER_DATADIR_ABS}" && find "hybridset" -type d -depth 2 | cut -d / -f 3 | sort -u)
}

hybridset_pkgcmd() {
	[ $# -ge 2 ] || eargs hybridset_pkgcmd rootdir pkgrootdir
	local rootdir="$1"
	local pkgrootdir="$2"
	shift 2
	local host_abi
	local pkgcmd

	get_host_abi host_abi
	if [ "${host_abi}" = "purecap" ]; then
		pkgcmd="pkg64"
		abifile="/usr/sbin/pkg64"
	else
		pkgcmd="pkg"
		abifile="/usr/bin/uname"
	fi

	env ABI_FILE="${abifile}" \
	    IGNORE_OSVERSION=yes \
	    PKG_DBDIR="${rootdir}${pkgrootdir}/var/db/pkg64" \
	    PKG_CACHEDIR="${rootdir}${pkgrootdir}/var/cache/pkg64" \
	    ASSUME_ALWAYS_YES=yes \
	    ${pkgcmd} \
	    -R "${rootdir}/etc/pkg64" \
	    -r "${rootdir}${pkgrootdir}" \
	    "${@}"
}
