#!/bin/bash


#
#  Makes Debs for recent ubuntu and debian
#

WORKDIR=`pwd`
BINUTILS_GIT="git://github.com/seank/FreeScale-s12x-binutils.git"
BINUTILS_TAR=binutils-trunk.tar.bz2
OUTDIR="${WORKDIR}"/Output
OTHERMIRROR=/var/cache/pbuilder/repo
BUILDDIR="${WORKDIR}"/build
NEWLIBDIR=newlib-1.18.0
BINUTILSPKGS="binutils-s12x binutils-xgate"
CPUS=5
#BINUTILSPKGS="binutils-xgate"
if test `uname -m` = "x86_64" ; then
	echo "Detected 64 bit machine, building for 32 and 64 bit"
	ARCHS="i386 amd64"
else
	echo "Detected 32 bit machine, building for 32 bit only"
	ARCHS="i386"
fi

#DEB_RELEASES="lucid natty oneiric precise quantal stable unstable testing"
DEB_RELEASES="precise"

# Builds the deb pkgs.  Assumes pdebuild has been setup and configured
# previously and has the rootimages setup for the distros specified
#
function build_debs {
#DEB_RELEASES="lucid"
for dist in `echo "${DEB_RELEASES}"` ; do
	for arch in `echo ${ARCHS}` ; do
		echo "Building for Distro $dist Arch $arch"
		DESTDIR="${OUTDIR}"/"${dist}"
		if [ ! -d "${DESTDIR}" ] ; then
			mkdir -p "${DESTDIR}"
		fi
		find ${OTHERMIRROR}  -type f -exec rm -f {} \;
		find ${DESTDIR} -type f -name "*$arch.deb" -exec cp -a {} ${OTHERMIRROR} \;
		pdebuild --architecture $arch --buildresult "${DESTDIR}" --pbuilderroot "sudo DIST=${dist} ARCH=${arch}" --debbuildopts -j4 -- --allow-untrusted
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
if [ ! -f "${WORKDIR}"/binutils-trunk ] ; then
	git clone "${BINUTILS_GIT}" binutils-trunk
	tar cvz --exclude=.git* -f "${WORKDIR}"/"${BINUTILS_TAR}" binutils-trunk
else
	pushd binutils-trunk >/dev/null
	git pull
	popd >/dev/null
	tar cvz --exclude=.git* -f "${WORKDIR}"/"${BINUTILS_TAR}" binutils-trunk
fi

for pkg in `echo "${BINUTILSPKGS}"` ; do
	mkdir -p "${BUILDDIR}"/"${pkg}"
	cp -a "${pkg}"/* "${BUILDDIR}"/"${pkg}"
	cp -a "${WORKDIR}"/"${BINUTILS_TAR}" "${BUILDDIR}"/"${pkg}"
	pushd "${BUILDDIR}"/"${pkg}" >/dev/null
	build_debs 
	popd >/dev/null
done
return $?
}

# Need to make GCC next
function build_gcc {
mkdir -p "${BUILDIR}"
pushd "${BUILDDIR}" >/dev/null
if [ ! -d FreeScale-s12x-gcc ] ; then
	git clone git://github.com/seank/FreeScale-s12x-gcc.git
fi
pushd FreeScale-s12x-gcc >/dev/null
git pull
pushd "${WORKDIR}"/gcc/ >/dev/null
VER=`dpkg-parsechangelog | grep ^"Version" | sed -r 's/Version: [0-9]{1}:([0-9\.].*dfsg)+.*/\1/'`
popd >/dev/null
if [ -d src ] ; then
	pushd src >/dev/null
	cp -a "${WORKDIR}"/gcc/* ./
	popd >/dev/null
	mv src gcc-mc9s12x_${VER}
else
	pushd gcc-mc9s12x_${VER} >/dev/null
	cp -a "${WORKDIR}"/gcc/* ./
	popd >/dev/null
fi
pushd gcc-mc9s12x_${VER}
build_debs
popd >/dev/null
popd >/dev/null
popd >/dev/null
return $?
}

# Need to make Newlib
function build_newlib {
mkdir -p "${BUILDIR}"
pushd "${BUILDDIR}" >/dev/null
if [ ! -d FreeScale-s12x-newlib ] ; then
	git clone git://github.com/seank/FreeScale-s12x-newlib.git
fi
pushd FreeScale-s12x-newlib >/dev/null
git pull
pushd src >/dev/null
cp -a "${WORKDIR}"/newlib/* ./
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

function clean {
rm  -f "${WORKDIR}"/"${BINUTILS_TAR}"
rm -rf "${BUILDDIR}"
rm -rf "${OUTDIR}"
}

function help {
echo "Run builddebs.sh all to rebuild everything"
echo "Run builddebs.sh build_binutils to just rebuild binutils"
echo "Run builddebs.sh build_gcc to just rebuild gcc"
echo "Run builddebs.sh build_newlib to just rebuild newlib"
echo "Run builddebs.sh build_metapkg to just rebuild newlib"
echo "Run builddebs.sh clean to cleanout build and output dirs"
echo ""
}

function all {
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
	echo "Attempting to run $1"
	$1
fi

