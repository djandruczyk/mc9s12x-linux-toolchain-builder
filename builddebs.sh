#!/bin/bash

#
#  Makes Debs for recent ubuntu and debian
#

WORKDIR=`pwd`
TMPDIR="${WORKDIR}/tmp"
BINUTILS_GIT="http://git.libreems.org/libreems-suite/s12x-binutils.git"
GCC_GIT="http://git.libreems.org/libreems-suite/s12x-gcc.git"
GCC_BRANCH="tmp-for-dave"
GCC_DIR="gcc-mc9s12x"
NEWLIB_GIT="http://git.libreems.org/libreems-suite/s12x-newlib.git"
NEWLIB_DIR="newlib-mc9s12x"
BINUTILS_URI="http://ftp.gnu.org/gnu/binutils/"
BINUTILS_TAR=binutils-2.24.tar.bz2
OUTDIR="${WORKDIR}"/Output
OTHERMIRROR=/var/cache/pbuilder/repo
BUILDDIR="${WORKDIR}"/build
NEWLIBDIR=newlib-1.18.0
BINUTILS_PKGS="binutils-mc9s12x binutils-xgate"
CPUS=`cat /proc/cpuinfo |grep -c ^processor:`
if test `uname -m` = "x86_64" ; then
	echo "Detected 64 bit machine, building for 32 and 64 bit"
	ARCHS="amd64 i386"
else
	echo "Detected 32 bit machine, building for 32 bit only"
	ARCHS="i386"
fi

DEB_RELEASES="precise quantal raring saucy stable unstable testing"

# Builds the deb pkgs.  Assumes pdebuild has been setup and configured
# previously and has the rootimages setup for the distros specified
#
function build_debs {
for dist in `echo "${DEB_RELEASES}"` ; do
	for arch in `echo ${ARCHS}` ; do
		echo "Building for Distro $dist Arch $arch"
		DESTDIR="${OUTDIR}"/"${dist}"/"${arch}"
		if [ ! -d "${DESTDIR}" ] ; then
			mkdir -p "${DESTDIR}"
		fi
		find ${OTHERMIRROR}  -type f -exec rm -f {} \;
		find ${DESTDIR} -type f -name "*$arch.deb" -exec cp -a {} ${OTHERMIRROR} \;
		case "${dist}" in
			stable|unstable|testing)
				OSTYPE="~Debian"
				case "${dist}" in
					unstable)
						OSRELEASE="~sid"
					;;
					stable)
						OSRELEASE="~wheezy"
					;;
					testing)
						OSRELEASE="~jessie"
					;;
				esac
			;;
			precise|quantal|raring|saucy)
				OSTYPE="~Ubuntu"
				OSRELEASE="~${dist}"
			;;
			*)
				echo "ERROR, ${dist} not handled!!!"
				exit -1
			;;
		esac
		
		# Set the distro in the changelog properly...
		perl -pi -e "s/\)/${OSTYPE}${OSRELEASE}\)/g if 1 .. 1" debian/changelog
		perl -pi -e "s/\ [a-zA-Z_]+;/\ ${dist};/g if 1 .. 1" debian/changelog
		pdebuild --architecture $arch --buildresult "${DESTDIR}" --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" -- --allow-untrusted
		perl -pi -e "s/${OSTYPE}${OSRELEASE}\)/)/g if 1 .. 1" debian/changelog
		# Set the distro in the changelog back to "unstable"
		perl -pi -e "s/\ [a-zA-Z_]+;/\ unstable;/g if 1 .. 1" debian/changelog
		if [ $? -ne 0 ] ; then
			echo "Build failure for Arch $arch Dist $dist"
			exit -1
		fi
		find ${OTHERMIRROR} -type f -exec rm -f {} \;
	done
done
}

function setup {
mkdir -p "${BUILDDIR}"
}

# Need to make multiple versions of binutils, 
# one for S12x, and one for Xgate
function build_binutils {
if [ ! -f ${TMPDIR}/${BINUTILS_TAR} ] ; then
	wget -c  ${BINUTILS_URI}/${BINUTILS_TAR} -O ${TMPDIR}/${BINUTILS_TAR}
else
	pushd "${TMPDIR}" >/dev/null
	md5sum --status -c "${BINUTILS_TAR}".md5
	RESULT=$?
	if [ ${RESULT} -ne 0 ] ; then
	    wget -c "${BINUTILS_URI}"/"${BINUTILS_TAR}" -O "${BINUTILS_TAR}"
	fi
	popd >/dev/null
fi

for pkg in `echo "${BINUTILS_PKGS}"` ; do
	mkdir -p "${BUILDDIR}"/"${pkg}"
	cp -a "${pkg}"/* "${BUILDDIR}"/"${pkg}"
	cp -a "${TMPDIR}"/"${BINUTILS_TAR}" "${BUILDDIR}"/"${pkg}"
	pushd "${BUILDDIR}"/"${pkg}" >/dev/null
	build_debs 
	popd >/dev/null
done
return $?
}

# Need to make GCC next
function build_gcc {
mkdir -p "${BUILDDIR}"
pushd "${BUILDDIR}" >/dev/null
if [ ! -d "${GCC_DIR}" ] ; then
	git clone  -b "${GCC_BRANCH}" "${GCC_GIT}" "${GCC_DIR}"
fi
pushd "${GCC_DIR}" >/dev/null
git pull
pushd "${WORKDIR}"/"${GCC_DIR}" >/dev/null
VER=`dpkg-parsechangelog | grep ^"Version" | sed -r 's/Version: [0-9]{1}:([0-9\.].*dfsg)+.*/\1/'`
popd >/dev/null
if [ -d src ] ; then
	pushd src >/dev/null
	cp -a "${WORKDIR}"/"${GCC_DIR}"/* ./
	popd >/dev/null
	mv src "${GCC_DIR}"_${VER}
else
	pushd "${GCC_DIR}"_${VER} >/dev/null
	cp -a "${WORKDIR}"/"${GCC_DIR}"/* ./
	popd >/dev/null
fi
pushd "${GCC_DIR}"_${VER}
build_debs
popd >/dev/null
popd >/dev/null
popd >/dev/null
return $?
}

# Need to make Newlib
function build_newlib {
mkdir -p "${BUILDDIR}"
pushd "${BUILDDIR}" >/dev/null
if [ ! -d "${NEWLIB_DIR}" ] ; then
	git clone "${NEWLIB_GIT}" "${NEWLIB_DIR}"
fi
pushd "${NEWLIB_DIR}" >/dev/null
git pull
pushd src >/dev/null
cp -a "${WORKDIR}"/"${NEWLIB_DIR}"/* ./
build_debs
popd >/dev/null
popd >/dev/null
popd >/dev/null
return $?
}

function build_metapkg {
for dist in `echo "${DEB_RELEASES}"` ; do
	VER=$(cat mc9s12x-toolchain/DEBIAN/control |grep Version |cut -f2 -d\ )
	dpkg-deb --build mc9s12x-toolchain && mv mc9s12x-toolchain.deb Output/${dist}/mc9s12x-toolchain-${VER}.deb
done
}

function build_clean {
rm  -f "${WORKDIR}"/"${BINUTILS_TAR}"
rm -rf "${BUILDDIR}"
rm -rf "${OUTDIR}"
}

function help {
echo "Run builddebs.sh all to rebuild everything"
echo "Run builddebs.sh binutils to just rebuild binutils"
echo "Run builddebs.sh gcc to just rebuild gcc"
echo "Run builddebs.sh newlib to just rebuild newlib"
echo "Run builddebs.sh metapkg to just rebuild the metapkg"
echo "Run builddebs.sh clean to cleanout build and output dirs"
echo ""
}

function build_all {
	echo "Rebuilding all (binutils, gcc, newlib)"
	setup
	build_binutils
	build_gcc
	build_newlib
	build_metapkg
}

if [ $# -eq 0 ] ; then
	help
fi

if [ $# -eq 1 ] ; then
	#echo "Attempting to run function build_$1"
	build_"${1}"
fi

