#!/bin/bash

#
#  Makes Debs for recent ubuntu and debian
#

WORKDIR=`pwd`
TMPDIR="${WORKDIR}/tmp"
BINUTILS_GIT="http://git.libreems.org/libreems-suite/s12x-binutils.git"
GCC_GIT="http://git.libreems.org/libreems-suite/s12x-gcc.git"
GCC_BRANCH="tmp-for-dave"
GCC_TAR="gcc-3.3.6.tar.bz2"
GCC_PKG="gcc-mc9s12x"
GCC_DIR="gcc-3.3.6"
NEWLIB_GIT="http://git.libreems.org/libreems-suite/s12x-newlib.git"
NEWLIB_DIR="newlib-mc9s12x"
BINUTILS_URI="http://ftp.gnu.org/gnu/binutils/"
BINUTILS_TAR="binutils-2.24.tar.bz2"
OUTDIR="${WORKDIR}"/Output
OTHERMIRROR=/var/cache/pbuilder/repo
BUILDDIR="${WORKDIR}"/build
BINUTILS_PKGS="binutils-mc9s12x binutils-xgate"
CPUS=`cat /proc/cpuinfo |grep -c ^processor:`
if test `uname -m` = "x86_64" ; then
	echo "Detected 64 bit machine, building for 32 and 64 bit"
	ARCHS="amd64 i386"
else
	echo "Detected 32 bit machine, building for 32 bit only"
	ARCHS="i386"
fi

if [ -z "${DEB_RELEASES}" ] ; then
	DEB_RELEASES="lucid precise quantal raring saucy stable unstable testing"
fi
echo "Building for \"${DEB_RELEASES}\""
#DEB_RELEASES="lucid"

# Builds the deb pkgs.  Assumes pdebuild has been setup and configured
# previously and has the rootimages setup for the distros specified
#
function build_debs {
for dist in `echo "${DEB_RELEASES}"` ; do
	perl -pi -e "s/\)/~${dist}\)/g if 1 .. 1" debian/changelog
	perl -pi -e "s/\ [a-z]+;/\ ${dist};/g if 1 .. 1" debian/changelog
	for arch in `echo ${ARCHS}` ; do
		echo "Building for Distro $dist Arch $arch"
		DESTDIR="${OUTDIR}"/"${dist}"/"${arch}"
		if [ ! -d "${DESTDIR}" ] ; then
			mkdir -p "${DESTDIR}"
		fi
		find ${OTHERMIRROR}  -type f -exec rm -f {} \;
		find ${DESTDIR} -type f -name "*$arch.deb" -exec cp -a {} ${OTHERMIRROR} \;
		#pdebuild --debbuildopts -j ${CPUS} --architecture $arch --buildresult "${DESTDIR}" --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" -- --allow-untrusted
		pdebuild --architecture $arch --buildresult "${DESTDIR}" --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" -- --allow-untrusted
		if [ $? -ne 0 ] ; then
			echo "Build failure for Arch $arch Dist $dist"
			exit -1
		fi
		find ${OTHERMIRROR} -type f -exec rm -f {} \;
	done
	perl -pi -e "s/\ ${dist};/\ unstable;/g if 1 .. 1" debian/changelog
	perl -pi -e "s/~${dist}\)/\)/g if 1 .. 1" debian/changelog
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
	pushd "${pkg}" >/dev/null
	ver=$(dpkg-parsechangelog | grep ^"Version" | sed -r 's/Version: [0-9]{1}:([0-9\.]+)-.*/\1/')
	popd >/dev/null
	# Remove stale crap...
	rm -rf "${BUILDDIR}"/"${pkg}"[_-]"${ver}"*
	mkdir -p "${BUILDDIR}"/"${pkg}"-"${ver}"
	cp -a "${TMPDIR}"/"${BINUTILS_TAR}" "${BUILDDIR}"/"${pkg}"-"${ver}"
	pushd "${BUILDDIR}" >/dev/null
	tar cvfj "${pkg}"_"${ver}".orig.tar.bz2 "${pkg}"-"${ver}"
	popd >/dev/null
	cp -a "${pkg}"/* "${BUILDDIR}"/"${pkg}"-"${ver}"
	pushd "${BUILDDIR}"/"${pkg}"-"${ver}" >/dev/null
	build_debs 
	popd >/dev/null
done
return $?
}

# Need to make GCC next
function build_gcc {
if [ ! -f ${TMPDIR}/${GCC_TAR} ] ; then
	wget -c  ${GCC_URI}/${GCC_TAR} -O ${TMPDIR}/${GCC_TAR}
else
	pushd "${TMPDIR}" >/dev/null
	md5sum --status -c "${GCC_TAR}".md5
	RESULT=$?
	if [ ${RESULT} -ne 0 ] ; then
	    wget -c "${GCC_URI}"/"${GCC_TAR}" -O "${GCC_TAR}"
	fi
	popd >/dev/null
fi
mkdir -p "${BUILDDIR}"
pushd "${WORKDIR}"/"${GCC_PKG}" >/dev/null
ver=$(dpkg-parsechangelog | grep ^"Version" | sed -r 's/Version: [0-9]{1}:([0-9\.].*dfsg)+.*/\1/')
popd >/dev/null
rm -rf "${BUILDDIR}"/"${GCC_PKG}"[_-]*
pushd "${BUILDDIR}" >/dev/null
echo "Copying in pristine GCC source"
tar xf "${TMPDIR}"/"${GCC_TAR}"
mv "${GCC_DIR}" "${GCC_PKG}"-"${ver}"
popd >/dev/null
cp -a "${GCC_PKG}"/* "${BUILDDIR}"/"${GCC_PKG}"-"${ver}"
pushd "${BUILDDIR}" >/dev/null
echo "Making deb .orig tarball"
tar cjf "${GCC_PKG}"_"${ver}".orig.tar.bz2 "${GCC_PKG}"-"${ver}"
pushd "${BUILDDIR}"/"${GCC_PKG}"-"${ver}" >/dev/null
build_debs 
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
	dpkg-deb --build mc9s12x-toolchain && mv mc9s12x-toolchain.deb Output/${dist}/mc9s12x-toolchain-${VER}~${dist}.deb
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

