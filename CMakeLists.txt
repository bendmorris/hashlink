cmake_minimum_required(VERSION 3.1)

cmake_policy(SET CMP0042 NEW)

include(GNUInstallDirs)
include(FindPkgConfig)

if (WIN32)
    project(hashlink C CXX) # C++ required for directx
else()
    project(hashlink C)
endif()

# force Unicode over Multi-byte
if (MSVC)
    add_definitions(-DUNICODE -D_UNICODE)
endif()

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if (CMAKE_VERSION VERSION_LESS "3.1")
    set (CMAKE_C_FLAGS "-std=c11 ${CMAKE_C_FLAGS}")
else ()
    set (CMAKE_C_STANDARD 11)
endif ()

# put output in "bin"

set(OUTPUT_DIR ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR})

# avoid the extra "Debug", "Release" directories
# http://stackoverflow.com/questions/7747857/in-cmake-how-do-i-work-around-the-debug-and-release-directories-visual-studio-2
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
    string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
    set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
    set( CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
    set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

set(HL_VERSION_MAJOR 0)
set(HL_VERSION_MINOR 1)
set(HL_VERSION_PATCH 0)
set(HL_VERSION ${HL_VERSION_MAJOR}.${HL_VERSION_MINOR}.${HL_VERSION_PATCH})

function(set_as_hdll target)
    set_target_properties(${target}.hdll
        PROPERTIES
        PREFIX ""
        OUTPUT_NAME ${target}
        SUFFIX .hdll
    )
endfunction()

include_directories(
    src
    include/pcre
)

file(GLOB pcre_srcs
    include/pcre/*.c
)
file(GLOB std_srcs
    src/std/array.c
    src/std/buffer.c
    src/std/bytes.c
    src/std/cast.c
    src/std/date.c
    src/std/error.c
    src/std/file.c
    src/std/fun.c
    src/std/maps.c
    src/std/math.c
    src/std/obj.c
    src/std/random.c
    src/std/regexp.c
    src/std/socket.c
    src/std/string.c
    src/std/sys.c
    src/std/types.c
    src/std/ucs2.c
    src/std/thread.c
    src/std/process.c
)

if (ANDROID)
    list(APPEND std_srcs
        src/std/sys_android.c
    )
endif()

if (IOS_PLATFORM)
    list(APPEND std_srcs
        src/std/sys_ios.m
    )
endif()

add_library(libhl SHARED
    ${pcre_srcs}
    src/alloc.c
    ${std_srcs}
)

set_target_properties(libhl
    PROPERTIES
        PUBLIC_HEADER
            "src/hl.h;src/hlc.h;src/hlc_main.c"
)

if(WIN32)
    set_target_properties(libhl
        PROPERTIES
        OUTPUT_NAME libhl
    )
else()
    set_target_properties(libhl
        PROPERTIES
        OUTPUT_NAME hl
    )
endif()

set_target_properties(libhl
    PROPERTIES
    VERSION ${HL_VERSION}
    SOVERSION ${HL_VERSION_MAJOR}
    COMPILE_DEFINITIONS "_USRDLL;LIBHL_EXPORTS"
)

add_executable(hl
    src/code.c
    src/jit.c
    src/main.c
    src/module.c
    src/debugger.c
)

target_link_libraries(hl libhl)

if(WIN32)
    target_link_libraries(libhl ws2_32 user32)
    target_link_libraries(hl user32)
else()
    target_link_libraries(libhl m dl pthread)
endif()

#####################
# hello.hl

find_program(
    HAXE_COMPILER
    haxe
)

add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/hello.hl
    COMMAND ${HAXE_COMPILER} -hl ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/hello.hl -cp ${CMAKE_SOURCE_DIR}/other/tests -main HelloWorld
)
add_custom_target(hello.hl ALL
    DEPENDS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/hello.hl
)

#####################
# ui.hdll

add_library(ui.hdll SHARED libs/ui/ui_stub.c)

if (WIN32)
    set_target_properties(ui.hdll PROPERTIES SOURCES libs/ui/ui_win.c)
endif()

set_as_hdll(ui)

target_link_libraries(ui.hdll
    libhl
)

#####################
# sdl.hdll

if (WIN32)
    set(SDL2_PATH ${CMAKE_SOURCE_DIR}/include/sdl)
endif()
find_package(SDL2 REQUIRED)

add_library(sdl.hdll SHARED
    libs/sdl/sdl.c
    libs/sdl/gl.c
)
set_as_hdll(sdl)
target_include_directories(sdl.hdll
    PRIVATE
    ${SDL2_INCLUDE_DIR}
    include/gl
)
target_link_libraries(sdl.hdll
    libhl
    ${SDL2_LIBRARY}
)

if(WIN32)
    target_link_libraries(sdl.hdll
        winmm
        opengl32
    )
endif()

if (APPLE)
    find_package(OPENGL REQUIRED)
    target_include_directories(sdl.hdll
        PRIVATE
        ${OPENGL_INCLUDE_DIR}
    )
    target_link_libraries(sdl.hdll
        libhl
        ${OPENGL_gl_LIBRARY}
    )
endif()

#####################
# fmt.hdll

if(WIN32)
    set(ZLIB_INCLUDE_DIRS include/zlib)
    set(PNG_INCLUDE_DIRS include/png)
    set(OGGVORBIS_INCLUDE_DIR include/vorbis)

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TurboJPEG_INCLUDE_DIRS include/turbojpeg include/turbojpeg/x64)
        find_library(TurboJPEG_LIBRARIES simd PATHS include/turbojpeg/x64)
    else()
        set(TurboJPEG_INCLUDE_DIRS include/turbojpeg include/turbojpeg/x86)
        find_library(TurboJPEG_LIBRARIES simd PATHS include/turbojpeg/x86)
    endif()

    add_library(fmt.hdll SHARED
        include/png/png.c
        include/png/pngerror.c
        include/png/pngget.c
        include/png/pngmem.c
        include/png/pngpread.c
        include/png/pngread.c
        include/png/pngrio.c
        include/png/pngrtran.c
        include/png/pngrutil.c
        include/png/pngset.c
        include/png/pngtrans.c
        include/png/pngwio.c
        include/png/pngwrite.c
        include/png/pngwtran.c
        include/png/pngwutil.c
        include/turbojpeg/jaricom.c
        include/turbojpeg/jcapimin.c
        include/turbojpeg/jcapistd.c
        include/turbojpeg/jcarith.c
        include/turbojpeg/jccoefct.c
        include/turbojpeg/jccolor.c
        include/turbojpeg/jcdctmgr.c
        include/turbojpeg/jchuff.c
        include/turbojpeg/jcinit.c
        include/turbojpeg/jcmainct.c
        include/turbojpeg/jcmarker.c
        include/turbojpeg/jcmaster.c
        include/turbojpeg/jcomapi.c
        include/turbojpeg/jcparam.c
        include/turbojpeg/jcphuff.c
        include/turbojpeg/jcprepct.c
        include/turbojpeg/jcsample.c
        include/turbojpeg/jctrans.c
        include/turbojpeg/jdapimin.c
        include/turbojpeg/jdapistd.c
        include/turbojpeg/jdarith.c
        include/turbojpeg/jdatadst-tj.c
        include/turbojpeg/jdatadst.c
        include/turbojpeg/jdatasrc-tj.c
        include/turbojpeg/jdatasrc.c
        include/turbojpeg/jdcoefct.c
        include/turbojpeg/jdcolor.c
        include/turbojpeg/jddctmgr.c
        include/turbojpeg/jdhuff.c
        include/turbojpeg/jdinput.c
        include/turbojpeg/jdmainct.c
        include/turbojpeg/jdmarker.c
        include/turbojpeg/jdmaster.c
        include/turbojpeg/jdmerge.c
        include/turbojpeg/jdphuff.c
        include/turbojpeg/jdpostct.c
        include/turbojpeg/jdsample.c
        include/turbojpeg/jdtrans.c
        include/turbojpeg/jerror.c
        include/turbojpeg/jfdctflt.c
        include/turbojpeg/jfdctfst.c
        include/turbojpeg/jfdctint.c
        include/turbojpeg/jidctflt.c
        include/turbojpeg/jidctfst.c
        include/turbojpeg/jidctint.c
        include/turbojpeg/jidctred.c
        include/turbojpeg/jmemmgr.c
        include/turbojpeg/jmemnobs.c
        include/turbojpeg/jquant1.c
        include/turbojpeg/jquant2.c
        include/turbojpeg/jsimd.c
        include/turbojpeg/jutils.c
        include/turbojpeg/transupp.c
        include/turbojpeg/turbojpeg.c
        include/zlib/adler32.c
        include/zlib/crc32.c
        include/zlib/deflate.c
        include/zlib/inffast.c
        include/zlib/inflate.c
        include/zlib/inftrees.c
        include/zlib/trees.c
        include/zlib/zutil.c
        include/vorbis/bitrate.c
        include/vorbis/bitwise.c
        include/vorbis/block.c
        include/vorbis/codebook.c
        include/vorbis/envelope.c
        include/vorbis/floor0.c
        include/vorbis/floor1.c
        include/vorbis/framing.c
        include/vorbis/info.c
        include/vorbis/lookup.c
        include/vorbis/lpc.c
        include/vorbis/lsp.c
        include/vorbis/mapping0.c
        include/vorbis/mdct.c
        include/vorbis/psy.c
        include/vorbis/registry.c
        include/vorbis/res0.c
        include/vorbis/sharedbook.c
        include/vorbis/smallft.c
        include/vorbis/synthesis.c
        include/vorbis/vorbisfile.c
        include/vorbis/window.c
        libs/fmt/fmt.c
        libs/fmt/sha1.c
    )
else()
    find_package(ZLIB REQUIRED)
    find_package(PNG REQUIRED)
    find_package(TurboJPEG REQUIRED)
    find_package(OggVorbis REQUIRED)

    add_library(fmt.hdll SHARED
        libs/fmt/fmt.c
        libs/fmt/sha1.c
    )
endif()


set_as_hdll(fmt)
target_include_directories(fmt.hdll
    PRIVATE
    ${ZLIB_INCLUDE_DIRS}
    ${PNG_INCLUDE_DIRS}
    ${TurboJPEG_INCLUDE_DIRS}
    ${OGGVORBIS_INCLUDE_DIR}
)
target_link_libraries(fmt.hdll
    libhl
    ${ZLIB_LIBRARIES}
    ${PNG_LIBRARIES}
    ${TurboJPEG_LIBRARIES}
    ${OGGVORBIS_LIBRARIES}
)
target_compile_definitions(fmt.hdll
    PRIVATE
    ${PNG_DEFINITIONS}
)

#####################
# sqlite.hdll

add_library(sqlite.hdll SHARED
    libs/sqlite/sqlite.c
    include/sqlite/src/sqlite3.c
)
set_as_hdll(sqlite)
target_include_directories(sqlite.hdll
    PRIVATE
    include/sqlite/src
)
target_link_libraries(sqlite.hdll
    libhl
)

#####################
# uv.hdll

add_library(uv.hdll SHARED
    libs/uv/uv.c
)

if (WIN32)
    target_sources(uv.hdll
        PRIVATE
            include/libuv/src/fs-poll.c
            include/libuv/src/inet.c
            include/libuv/src/threadpool.c
            include/libuv/src/uv-common.c
            include/libuv/src/version.c
            include/libuv/src/win/async.c
            include/libuv/src/win/core.c
            include/libuv/src/win/dl.c
            include/libuv/src/win/error.c
            include/libuv/src/win/fs-event.c
            include/libuv/src/win/fs.c
            include/libuv/src/win/getaddrinfo.c
            include/libuv/src/win/getnameinfo.c
            include/libuv/src/win/handle.c
            include/libuv/src/win/loop-watcher.c
            include/libuv/src/win/pipe.c
            include/libuv/src/win/poll.c
            include/libuv/src/win/process-stdio.c
            include/libuv/src/win/process.c
            include/libuv/src/win/req.c
            include/libuv/src/win/signal.c
            include/libuv/src/win/snprintf.c
            include/libuv/src/win/stream.c
            include/libuv/src/win/tcp.c
            include/libuv/src/win/thread.c
            include/libuv/src/win/timer.c
            include/libuv/src/win/tty.c
            include/libuv/src/win/udp.c
            include/libuv/src/win/util.c
            include/libuv/src/win/winapi.c
            include/libuv/src/win/winsock.c
    )
else()
    find_package(LibUV)
endif()

set_as_hdll(uv)
target_link_libraries(uv.hdll
    libhl
)
if (WIN32)
    target_include_directories(uv.hdll
        PRIVATE
        include/libuv/include
    )
    target_link_libraries(uv.hdll
        psapi
        iphlpapi
        userenv
    )
else()
    target_include_directories(uv.hdll
        PRIVATE
        ${LibUV_INCLUDE_DIRS}
    )
    target_link_libraries(uv.hdll
        ${LibUV_LIBRARIES}
    )
endif()

#####################
# directx.hdll

if(WIN32)
    find_package(DirectX)
    add_library(directx.hdll SHARED
        libs/directx/directx.cpp
        libs/directx/gamecontroller.c
        libs/directx/window.c
    )
    set_as_hdll(directx)
    target_link_libraries(directx.hdll
        libhl
        d3d11
        dxgi
        d3dcompiler
        xinput9_1_0
        dinput8
    )
endif()


#####################
# ssl.hdll
# TODO: unix

if(WIN32)
    add_library(ssl.hdll SHARED
        include/mbedtls/library/aes.c
        include/mbedtls/library/aesni.c
        include/mbedtls/library/arc4.c
        include/mbedtls/library/asn1parse.c
        include/mbedtls/library/asn1write.c
        include/mbedtls/library/base64.c
        include/mbedtls/library/bignum.c
        include/mbedtls/library/blowfish.c
        include/mbedtls/library/camellia.c
        include/mbedtls/library/ccm.c
        include/mbedtls/library/certs.c
        include/mbedtls/library/cipher.c
        include/mbedtls/library/cipher_wrap.c
        include/mbedtls/library/ctr_drbg.c
        include/mbedtls/library/debug.c
        include/mbedtls/library/des.c
        include/mbedtls/library/dhm.c
        include/mbedtls/library/ecdh.c
        include/mbedtls/library/ecdsa.c
        include/mbedtls/library/ecjpake.c
        include/mbedtls/library/ecp.c
        include/mbedtls/library/ecp_curves.c
        include/mbedtls/library/entropy.c
        include/mbedtls/library/entropy_poll.c
        include/mbedtls/library/error.c
        include/mbedtls/library/gcm.c
        include/mbedtls/library/havege.c
        include/mbedtls/library/hmac_drbg.c
        include/mbedtls/library/md.c
        include/mbedtls/library/md2.c
        include/mbedtls/library/md4.c
        include/mbedtls/library/md5.c
        include/mbedtls/library/md_wrap.c
        include/mbedtls/library/memory_buffer_alloc.c
        include/mbedtls/library/oid.c
        include/mbedtls/library/padlock.c
        include/mbedtls/library/pem.c
        include/mbedtls/library/pk.c
        include/mbedtls/library/pkcs11.c
        include/mbedtls/library/pkcs12.c
        include/mbedtls/library/pkcs5.c
        include/mbedtls/library/pkparse.c
        include/mbedtls/library/pkwrite.c
        include/mbedtls/library/pk_wrap.c
        include/mbedtls/library/platform.c
        include/mbedtls/library/ripemd160.c
        include/mbedtls/library/rsa.c
        include/mbedtls/library/sha1.c
        include/mbedtls/library/sha256.c
        include/mbedtls/library/sha512.c
        include/mbedtls/library/ssl_cache.c
        include/mbedtls/library/ssl_ciphersuites.c
        include/mbedtls/library/ssl_cli.c
        include/mbedtls/library/ssl_cookie.c
        include/mbedtls/library/ssl_srv.c
        include/mbedtls/library/ssl_ticket.c
        include/mbedtls/library/ssl_tls.c
        include/mbedtls/library/threading.c
        include/mbedtls/library/timing.c
        include/mbedtls/library/version.c
        include/mbedtls/library/version_features.c
        include/mbedtls/library/x509.c
        include/mbedtls/library/x509write_crt.c
        include/mbedtls/library/x509write_csr.c
        include/mbedtls/library/x509_create.c
        include/mbedtls/library/x509_crl.c
        include/mbedtls/library/x509_crt.c
        include/mbedtls/library/x509_csr.c
        include/mbedtls/library/xtea.c
        libs/ssl/ssl.c
    )
    set_as_hdll(ssl)
    target_include_directories(ssl.hdll
        PRIVATE
        include/mbedtls/include
    )
    target_link_libraries(ssl.hdll
        libhl
        crypt32
    )
endif()

#####################
# Tests

include(CTest)
add_test(NAME hello.hl
    COMMAND hl ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/hello.hl
)

#####################
# Packaging

set(CPACK_PACKAGE_VENDOR "Haxe Foundation")
set(CPACK_PACKAGE_VERSION_MAJOR ${HL_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${HL_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${HL_VERSION_PATCH})
set(CPACK_GENERATOR ZIP)

install(
    TARGETS
        hl
        libhl
        fmt.hdll
        ui.hdll
        sdl.hdll
        sqlite.hdll
        uv.hdll
    DESTINATION .
    PUBLIC_HEADER DESTINATION include
)

if (WIN32)
    install(
        TARGETS
            directx.hdll
            ssl.hdll
        DESTINATION .
    )
endif()

if (DEFINED ENV{APPVEYOR_REPO_COMMIT})
    set(CPACK_PACKAGE_VERSION $ENV{APPVEYOR_REPO_COMMIT})
endif()

include(CPack)
