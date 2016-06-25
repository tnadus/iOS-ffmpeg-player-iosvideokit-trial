#!/bin/sh

#  Build script modified by Tarum Nadus
#  supports both AppleTVOS and AppleTVSimulator

# Text color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}


`sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer`

#extra libs

#BUILD & USE OPENSSL IF VALUE IS 1
USEOPENSSL=1
SKIP_COMPILE=0
ENABLE_BITCODE=1

#ffmpeg version & TVOS SDK version
VERSION="2.8.1"
SDKVERSION=`xcrun -sdk appletvos --show-sdk-version`
DEPLOYMENT_TARGET="9.0"

echo "\n"
echo "$(tput smul)$(tput bold)Build configuration for TVOS (Needs Xcode 7 to build) $(tput sgr 0)\n"
echo "$(tput setaf 2)FFMPEG VERSION       :  ${VERSION}$(tput sgr 0)"
echo "$(tput setaf 2)SDKVERSION           :  ${SDKVERSION}$(tput sgr 0)"
echo "$(tput setaf 2)DEPLOYMENT_TARGET    :  ${DEPLOYMENT_TARGET}$(tput sgr 0)"
echo "$(tput setaf 2)USE OPENSSL ?        :  ${USEOPENSSL}$(tput sgr 0)"

SDK_NUM_MAJOR=${SDKVERSION:0:1}

if [ "$SDK_NUM_MAJOR" -lt 9 ] && [ "$ENABLE_BITCODE" -eq 1 ]
then
	ENABLE_BITCODE=0
	echo "$(tput setaf 2)ENABLE BITCODE ?     :  ${ENABLE_BITCODE} (No BITCODE support for ${SDK_NUM_MAJOR}.X SDK) $(tput sgr 0)"
else
	echo "$(tput setaf 2)ENABLE BITCODE ?     :  ${ENABLE_BITCODE}$(tput sgr 0)"
fi

echo ""

CURRENTPATH=`pwd`
ARCHS="x86_64 arm64"
#ARCHS="armv7"
CC=""
CFLAGS=""
ARCHCOUNT=0

set -e
if [ ! -e ffmpeg-${VERSION}.tar.bz2 ]; then
	echo "Downloading ffmpeg-${VERSION}.tar.bz2"
    curl -O  http://ffmpeg.org/releases/ffmpeg-${VERSION}.tar.bz2
else
	echo "Using ffmpeg-${VERSION}.tar.bz2"
fi

if [ "$SKIP_COMPILE" -eq 0 ]
then
	rm -R -f "${CURRENTPATH}/src"
	rm -R -f "${CURRENTPATH}/bin"
	rm -R -f "${CURRENTPATH}/lib-tvos"

	mkdir -p "${CURRENTPATH}/src"
	mkdir -p "${CURRENTPATH}/bin"
	mkdir -p "${CURRENTPATH}/lib-tvos"
	
	echo "extracting tar file now..."
	tar jxf ffmpeg-${VERSION}.tar.bz2 -C "${CURRENTPATH}/src"
	echo "extracting done"
	
	echo "checking for mlpdsp patch..."
	
	if [ ! -e mlpdsp.patch ]; then
    	echo "Patch for mlpdsp not found"
    exit 1
	else
    	cp mlpdsp.patch "${CURRENTPATH}/src/ffmpeg-${VERSION}"
    	cd "${CURRENTPATH}/src/ffmpeg-${VERSION}"
    	echo "patch for mlpdsp found"
    	patch -p0 -i mlpdsp.patch
    	if [ $? -gt 0 ]; then
        	echo "patch for mlpdsp error! exiting.."
        exit 1
    	else
        	echo "patch for mlpdsp is done successfully"
    	fi
	fi
	
	cd "${CURRENTPATH}"
	
	if [ ! -e mux.patch ]; then
    	echo "Patch for mux not found"
    exit 1
	else
    	cp mux.patch "${CURRENTPATH}/src/ffmpeg-${VERSION}/libavformat"
    	cd "${CURRENTPATH}/src/ffmpeg-${VERSION}/libavformat"
    	echo "patch for mux found"
    	patch -p0 -i mux.patch
    	if [ $? -gt 0 ]; then
        	echo "patch for mux error! exiting.."
        exit 1
    	else
        	echo "patch for mux is done successfully"
    	fi
	fi
fi

if [ "$USEOPENSSL" -eq 1 ]
then
  cd "${CURRENTPATH}"
  mkdir -p "openSSL"
  cp "build-libssl-tvos.sh" "./openSSL/build-libssl.sh"
  cd  "./openSSL/"
  
  LIBCOUNT=$(find ./lib-tvos -type f | wc -l)
  if [ $LIBCOUNT -eq 0 ]
  then
    echo "$(tput setaf 2)Building openSSL library now ...$(tput sgr 0)"
    cmd=`./build-libssl.sh ${ENABLE_BITCODE}`
    if [ $? -eq 0 ]
    then
      echo "ssl built successfully"
      cd ../
    else 
	  echo "ssl did not built"    
	  exit 0
    fi
  else
    echo "ssl is already built"
  fi
fi

for ARCH in ${ARCHS}
do
	ARCHCOUNT=`expr $ARCHCOUNT + 1`
	echo "building $ARCH ..."
	
	CFLAGS="-arch $ARCH"
	if [ "$ARCH" = "x86_64" ]
	then
		PLATFORM="AppleTVSimulator"
		CFLAGS="$CFLAGS -mtvos-simulator-version-min=$DEPLOYMENT_TARGET"
	else
		PLATFORM="AppleTVOS"
		CFLAGS="$CFLAGS -mtvos-version-min=$DEPLOYMENT_TARGET"
		
		if [ "$ARCH" = "arm64" ]
		then
			EXPORT="GASPP_FIX_XCODE5=1"
		fi
	fi
	
	XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
	CC="xcrun -sdk $XCRUN_SDK clang"
	CXXFLAGS="$CFLAGS"
	LDFLAGS="$CFLAGS"	

	echo "$(tput setaf 2)Configuring ffmpeg-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}$(tput sgr 0)"
	echo "Please stand by..."

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-ffmpeg-${VERSION}.log"


####################################################
####################################################
#              ffmpeg extra flags                  #
############                         ###############

FFMPEG_EXTRA_FLAGS="--enable-cross-compile --enable-pic"

# binaries & doc & debug
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-programs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-doc"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-debug"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-stripping"

# libraries
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-static"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-bzlib"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-avfilter"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-avdevice"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-postproc"

# encoders & decoders
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-encoders"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=ac3"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=ac3_fixed"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=eac3"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-decoder=mlp"

# muxers & demuxers
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-demuxers"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-muxers"

#3rd party libraries
if [ "$USEOPENSSL" -eq 1 ]
then
	FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --enable-openssl --extra-cflags=-I../../openSSL/include-tvos --extra-ldflags=-L../../openSSL/lib-tvos"
fi

# Others
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-devices"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-indevs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-outdevs"
FFMPEG_EXTRA_FLAGS="$FFMPEG_EXTRA_FLAGS --disable-filters"

cd "${CURRENTPATH}/src/ffmpeg-${VERSION}"

############                         ###############
#              ffmpeg extra flags                  #
####################################################
####################################################


if [ "$ENABLE_BITCODE" -eq 1 ]
then
	CC="${CC} -fembed-bitcode"
fi

echo "------------ >"
echo "arch = ${ARCH}"
echo "cc ${CC}"
echo "ff_ex_f = ${FFMPEG_EXTRA_FLAGS}"
echo "cf = $CFLAGS"
echo "df = $LDFLAGS"
echo "pre = ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
echo "< -----------"

if [ "$SKIP_COMPILE" -eq 0 ]
then
	./configure \
	--target-os=darwin \
	--arch=${ARCH} \
	--cc="$CC" \
	${FFMPEG_EXTRA_FLAGS} \
	--extra-cflags="-I../../include-tvos $CFLAGS" \
	--extra-ldflags="-L../../lib-tvos $LDFLAGS" \
	--extra-cxxflags="$CXXFLAGS" \
	${EXTRA_FLAGS} \
	--prefix=${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk \

	echo "configure is done."
	echo "$(tput setaf 2)compiling for ${ARCH} now ...$(tput sgr 0)"

    make -j8 V=1 >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
fi
done

echo "compile is done."

FFMPEG_LIBS="libavcodec libavformat libavutil libswscale libswresample"

echo "total arch count is $ARCHCOUNT"

echo "Merging libraries"
for i in ${FFMPEG_LIBS}
	do 
		lipo -create \
		${CURRENTPATH}/bin/AppleTVSimulator${SDKVERSION}-x86_64.sdk/lib/$i.a \
		${CURRENTPATH}/bin/AppleTVOS${SDKVERSION}-arm64.sdk/lib/$i.a \
	   	-output ${CURRENTPATH}/lib-tvos/$i.a
done


if [ $ARCHCOUNT -gt 1 ]
then
	mkdir -p ${CURRENTPATH}/include-tvos

	for i in ${FFMPEG_LIBS}
	do
	cp -R ${CURRENTPATH}/bin/AppleTVSimulator${SDKVERSION}-x86_64.sdk/include/$i ${CURRENTPATH}/include-tvos/
	done
fi

echo "Building done."

echo "$(tput setaf 2)Copying extra header files ...$(tput sgr 0)"

cp "cmdutils_common_opts.h" "../../include-tvos/cmdutils_common_opts.h"
cp "cmdutils.h" "../../include-tvos/cmdutils.h"
cp "config.h" "../../include-tvos/config.h"
cp "ffmpeg.h" "../../include-tvos/ffmpeg.h"
#cp "version.h" "../../include-tvos/version.h"

mkdir -p "../../include-tvos/compat"
cp "compat/va_copy.h" "../../include-tvos/compat/va_copy.h"

cp "libavcodec/get_bits.h" "../../include-tvos/libavcodec/get_bits.h"
cp "libavcodec/mathops.h" "../../include-tvos/libavcodec/mathops.h"

mkdir -p "../../include-tvos/libavcodec/arm"
cp "libavcodec/arm/mathops.h" "../../include-tvos/libavcodec/arm/mathops.h"

mkdir -p "../../include-tvos/libavdevice"
cp "libavdevice/avdevice.h" "../../include-tvos/libavdevice/avdevice.h"
cp "libavdevice/version.h" "../../include-tvos/libavdevice/version.h"

mkdir -p "../../include-tvos/libavfilter"
cp "libavfilter/avfilter.h" "../../include-tvos/libavfilter/avfilter.h"
cp "libavfilter/version.h" "../../include-tvos/libavfilter/version.h"

cp "libavformat/network.h" "../../include-tvos/libavformat/network.h"
cp "libavformat/os_support.h" "../../include-tvos/libavformat/os_support.h"
cp "libavformat/url.h" "../../include-tvos/libavformat/url.h"
cp "libavformat/rtspcodes.h" "../../include-tvos/libavformat/rtspcodes.h"
cp "libavformat/rtsp.h" "../../include-tvos/libavformat/rtsp.h"
cp "libavformat/srtp.h" "../../include-tvos/libavformat/srtp.h"
cp "libavformat/httpauth.h" "../../include-tvos/libavformat/httpauth.h"
cp "libavformat/rtp.h" "../../include-tvos/libavformat/rtp.h"
cp "libavformat/rtpdec.h" "../../include-tvos/libavformat/rtpdec.h"
cp "libavformat/http.h" "../../include-tvos/libavformat/http.h"

mkdir -p "../../include-tvos/libavresample"
cp "libavresample/avresample.h" "../../include-tvos/libavresample/avresample.h"
cp "libavresample/version.h" "../../include-tvos/libavresample/version.h"

mkdir -p "../../include-tvos/libpostproc"
cp "libpostproc/postprocess.h" "../../include-tvos/libpostproc/postprocess.h"
cp "libpostproc/version.h" "../../include-tvos/libpostproc/version.h"

cp "libavutil/libm.h" "../../include-tvos/libavutil/libm.h"

echo "copying is done"

echo "$(tput setaf 2) **************"
echo "[TVOS] Success..., please don't forget to update lib and include folders with new ones in Video framework - if ssl is built, then update those libraries too"
echo "************** $(tput sgr 0)"
