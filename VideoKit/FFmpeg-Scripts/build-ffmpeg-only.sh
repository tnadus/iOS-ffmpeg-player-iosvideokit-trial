#!/bin/sh

#  Build script modified by Tarum Nadus
#  supports both iPhoneOS and iPhoneSimulator

#ffmpeg version & IOS SDK version
VERSION="1.2.1"
SDKVERSION="7.0"
MINOSVER="5.0"

CURRENTPATH=`pwd`
ARCHS="i386 armv7 armv7s"
#ARCHS="i386 armv7 armv7s arm64"
#ARCHS="arm64"
#ARCHS="armv7"
DEVELOPER=`xcode-select -print-path`
CC=""
ARCHCOUNT=0

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

set -e
if [ ! -e ffmpeg-${VERSION}.tar.bz2 ]; then
	echo "Downloading ffmpeg-${VERSION}.tar.bz2"
    curl -O  http://ffmpeg.org/releases/ffmpeg-${VERSION}.tar.bz2
else
	echo "Using ffmpeg-${VERSION}.tar.bz2"
fi

rm -R -f "${CURRENTPATH}/src"
rm -R -f "${CURRENTPATH}/bin"
rm -R -f "${CURRENTPATH}/lib"

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

echo "extracting tar file now..."
tar jxf ffmpeg-${VERSION}.tar.bz2 -C "${CURRENTPATH}/src"

echo "checking for udp patch..."

if [ ! -e udp.patch ]; then
    echo "Patch not found"
    cd "${CURRENTPATH}/src/ffmpeg-${VERSION}"
else
    cp udp.patch "${CURRENTPATH}/src/ffmpeg-${VERSION}"
    cd "${CURRENTPATH}/src/ffmpeg-${VERSION}"
    echo "patch found"
    patch -p0 -i udp.patch
    if [ $? -gt 0 ]; then
        echo "patch error! exiting.."
        exit 1
    else
        echo "patch is done successfully"
    fi
fi

for ARCH in ${ARCHS}
do
	ARCHCOUNT=`expr $ARCHCOUNT + 1`
	
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
		EXTRA_FLAGS="--cpu=i386 --enable-pic --disable-asm"
        EXTRA_CFLAGS=""
        FFARCH=i386
        CC=${DEVELOPER}/usr/bin/gcc
	else
		PLATFORM="iPhoneOS"
		EXTRA_FLAGS="--enable-pic --enable-neon --enable-optimizations"
        EXTRA_CFLAGS="-mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
        FFARCH=arm
        CC=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
        
        if [ "${ARCH}" == "arm64" ];	
		then
			MINOSVER="7.0";
			EXTRA_FLAGS="$EXTRA_FLAGS --disable-asm"
			echo $MINOSVER
			echo $EXTRA_FLAGS
		else
			MINOSVER="5.0";
			EXTRA_FLAGS="$EXTRA_FLAGS --enable-asm"
			echo $MINOSVER
			echo $EXTRA_FLAGS		
		fi
	fi
		
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
	export RANLIB=${CROSS_TOP}/usr/bin/ranlib

	echo "Configuring ffmpeg-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-ffmpeg-${VERSION}.log"


####################################################
####################################################
#              ffmpeg extra flags                  #
############                         ###############

FFMPEG_EXTRA_FLAGS=""

# binaries & doc & debug
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-ffmpeg"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-ffserver"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-ffplay"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-ffprobe"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-doc"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-debug"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-stripping"

# libraries
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-static"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-bzlib"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-avfilter"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-avdevice"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-postproc"

# optimization flags
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-yasm"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-armv5te"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-armv6"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-armv6t2"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-mmx"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-vis"

# encoders & decoders
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-encoders"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=ac3"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=eac3"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=mlp"

# muxers & demuxers
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-demuxers"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-muxers"

# No HW Acceleration on IOS
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-hwaccels"

# Others
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-bsfs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-devices"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-indevs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-outdevs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-filters"


############                         ###############
#              ffmpeg extra flags                  #
####################################################
####################################################

./configure \
--cc=${CC} \
--as="gas-preprocessor.pl ${CC}" \
--prefix=${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk \
--sysroot=${CROSS_TOP}/SDKs/${CROSS_SDK} \
--extra-cflags="-I../../include" \
--extra-ldflags="-L../../lib" \
--extra-ldflags="-L${CROSS_TOP}/SDKs/${CROSS_SDK}/usr/lib/system" \
--target-os=darwin \
--arch=${FFARCH} \
--extra-cflags="-arch ${ARCH}  -miphoneos-version-min=${MINOSVER}" \
--extra-ldflags="-arch ${ARCH}  -miphoneos-version-min=${MINOSVER}" \
--enable-cross-compile \
${EXTRA_FLAGS} \
${FFMPEG_EXTRA_FLAGS} \

echo "configure is done."

echo "compiling now ..."
    make -j8 V=1 >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
done

echo "compile is done."

FFMPEG_LIBS="libavcodec libavformat libavutil libswscale libswresample"

echo $ARCHCOUNT

if [ $ARCHCOUNT -eq 3 ]
then
	echo "Merging libraries"
	for i in ${FFMPEG_LIBS}
	do 
		lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/$i.a \
		${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/$i.a \
	  	${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/$i.a \
	   	-output ${CURRENTPATH}/lib/$i.a
	done	
elif [ $ARCHCOUNT -eq 4 ]
then
	echo "Merging libraries"
	for i in ${FFMPEG_LIBS}
	do 
		lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/$i.a \
		${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/$i.a \
	  	${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/$i.a \
	  	${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/$i.a \
	   	-output ${CURRENTPATH}/lib/$i.a
done
fi

if [ $ARCHCOUNT -gt 1 ]
then
	mkdir -p ${CURRENTPATH}/include

	for i in ${FFMPEG_LIBS}
	do
	cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/$i ${CURRENTPATH}/include/
	done
fi

echo "Building done."
echo "Success..., please don't forget to update lib and include folder with new ones in Video framework"
