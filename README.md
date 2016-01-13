# curl-ios-build-shell-script
Build libcurl with shell script - only support to use on iOS, and bitcode is supported.

# Usage
1.Download curl source code(gz, zip and bz2 fromat are supported), e.g. curl-7.46.0.tar.bz2 

2.Move curl-build.sh into the folder where the curl-7.46.0.tar.bz2 is cotained.

3.Edit curl-build.sh, set the value of CURL_COMPRESSED_FN and -miphoneos-version-min( supported minimal iOS version ).
If you want to support the bitcode, find "export CFLAGS=-arch ${ARCH} -isysroot ${IOS_SDK_PATH} -miphoneos-version-min=6.0", add the -fembed-bitcode option at end of line. You must change the value of "--with-ssl" where the openssl libraries are installed, or disable ssl with "--without-ssl".

4.cd the the folder where the curl-7.46.0.tar.bz2 is cotained.

5.Execute curl-build.sh, libraries are created at "curl-version-build/universal/".
