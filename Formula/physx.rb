class Physx < Formula
  desc "Scalable multi-platform physics SDK supporting a wide range of devices"
  homepage "https://developer.nvidia.com/physx-sdk"
  url "https://github.com/NVIDIAGameWorks/PhysX/archive/c3d5537bdebd6f5cd82fcaf87474b838fe6fd5fa.tar.gz"
  version "4.1.2.29873463"
  sha256 "03ec80617033365520d261e6b049f2576596ea41cc2097741cc3771aeda5f2b8"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/NVIDIAGameWorks/PhysX.git", branch: "4.1"

  bottle do
    root_url "https://github.com/dpogue/homebrew-plasma-deps/releases/download/physx-4.1.2.29873463"
    sha256 cellar: :any,                 big_sur:      "0a2344e6ff4c075b1ef29d3d60fa3fdd690ce13cea17d870340e69beee37b979"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "d4891538a578315e1bf75a3c8953bf8aa681a676ea63375ff96140a755eff01a"
  end

  depends_on "cmake" => :build

  # Patch to removed -Werror and add Apple Silicon support
  patch :DATA

  def install
    mkdir "build" do
      args = std_cmake_args + %W[
        -DPHYSX_ROOT_DIR=#{buildpath}/physx
        -DPXSHARED_PATH=#{buildpath}/pxshared
        -DPXSHARED_INSTALL_PREFIX=#{prefix}
        -DCMAKEMODULES_PATH=#{buildpath}/externals/cmakemodules
        -DPX_OUTPUT_BIN_DIR=#{buildpath}/build
        -DPX_OUTPUT_LIB_DIR=#{buildpath}/build
        -DTARGET_BUILD_PLATFORM=#{OS.linux? ? "linux" : "mac"}
      ]

      system "cmake", "../physx/compiler/public", *args
      system "make", "install"

      # CMake puts the libraries deeply nested under the bin folder
      # but we want them in lib, where they belong
      lib.install Dir["#{bin}/**/*.{so,a,dylib,lib,dll}"] + Dir["#{buildpath}/build/bin/**/*.{so,a,dylib,lib,dll}"]

      rm_rf bin
      rm_rf "#{prefix}/source"
    end

    deuniversalize_machos
  end

  test do
    (testpath/"example.cpp").write <<~EOS
      #include <ctype.h>
      #include <PxPhysicsAPI.h>

      using namespace physx;

      int main(int argc, char *argv[])
      {
          PxDefaultAllocator allocator;
          PxDefaultErrorCallback errorCallback;
          PxFoundation* foundation = PxCreateFoundation(PX_PHYSICS_VERSION, allocator, errorCallback);

          if (foundation) {
              foundation->release();
              foundation = nullptr;
          }
          return 0;
      }
    EOS

    libs = %w[
      -pthread
      -lPhysX
      -lPhysXCommon
      -lPhysXFoundation
      -lPhysXExtensions_static
    ]
    system ENV.cxx, "example.cpp", "-DNDEBUG", "-I#{include}", "-L#{lib}", *libs
  end
end

__END__
diff --git a/externals/cmakemodules/GetCompilerAndPlatform.cmake b/externals/cmakemodules/GetCompilerAndPlatform.cmake
index 3ab5cfbf..ace464b0 100644
--- a/externals/cmakemodules/GetCompilerAndPlatform.cmake
+++ b/externals/cmakemodules/GetCompilerAndPlatform.cmake
@@ -103,7 +103,13 @@ FUNCTION (GetPlatformBinName PLATFORM_BIN_NAME LIBPATH_SUFFIX)
 	ELSEIF(TARGET_BUILD_PLATFORM STREQUAL "uwp")
 		SET(RETVAL "uwp.${PX_OUTPUT_ARCH}_${LIBPATH_SUFFIX}.${COMPILER}")
 	ELSEIF(TARGET_BUILD_PLATFORM STREQUAL "mac")
-		SET(RETVAL "mac.x86_${LIBPATH_SUFFIX}")
+		IF(PX_OUTPUT_ARCH STREQUAL "x86")
+			SET(RETVAL "mac.x86_${LIBPATH_SUFFIX}")
+		ELSEIF(PX_OUTPUT_ARCH STREQUAL "arm")
+			SET(RETVAL "mac.arm_${LIBPATH_SUFFIX}")
+		ELSE()
+			SET(RETVAL "mac.universal")
+		ENDIF()
 	ELSEIF(TARGET_BUILD_PLATFORM STREQUAL "ios")
 		SET(RETVAL "ios.arm_${LIBPATH_SUFFIX}")
 	ELSEIF(TARGET_BUILD_PLATFORM STREQUAL "ps4")
diff --git a/physx/source/compiler/cmake/android/CMakeLists.txt b/physx/source/compiler/cmake/android/CMakeLists.txt
index 06e0d98b..e6a77f17 100644
--- a/physx/source/compiler/cmake/android/CMakeLists.txt
+++ b/physx/source/compiler/cmake/android/CMakeLists.txt
@@ -33,15 +33,15 @@ STRING(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWERCASE)
 SET(PHYSX_WARNING_DISABLES "-Wno-invalid-offsetof -Wno-maybe-uninitialized  -Wno-unused-variable -Wno-variadic-macros -Wno-array-bounds -Wno-strict-aliasing")
 
 IF(${ANDROID_ABI} STREQUAL "armeabi-v7a")
-	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -funwind-tables -fomit-frame-pointer -funswitch-loops -finline-limit=300 -fno-strict-aliasing -fstack-protector ${PHYSX_WARNING_DISABLES}" CACHE INTERNAL "PhysX CXX")
+	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -funwind-tables -fomit-frame-pointer -funswitch-loops -finline-limit=300 -fno-strict-aliasing -fstack-protector ${PHYSX_WARNING_DISABLES}" CACHE INTERNAL "PhysX CXX")
 ELSEIF(${ANDROID_ABI} STREQUAL "armeabi-v7a with NEON")
-	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -funwind-tables -fomit-frame-pointer -funswitch-loops -finline-limit=300 -fno-strict-aliasing -fstack-protector ${PHYSX_WARNING_DISABLES}" CACHE INTERNAL "PhysX CXX")
+	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -funwind-tables -fomit-frame-pointer -funswitch-loops -finline-limit=300 -fno-strict-aliasing -fstack-protector ${PHYSX_WARNING_DISABLES}" CACHE INTERNAL "PhysX CXX")
 ELSEIF(${ANDROID_ABI} STREQUAL "arm64-v8a")
-	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} " CACHE INTERNAL "PhysX CXX")
+	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} " CACHE INTERNAL "PhysX CXX")
 ELSEIF(${ANDROID_ABI} STREQUAL "x86")
-	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} -fpack-struct=8 -malign-double " CACHE INTERNAL "PhysX CXX")
+	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} -fpack-struct=8 -malign-double " CACHE INTERNAL "PhysX CXX")
 ELSEIF(${ANDROID_ABI} STREQUAL "x86_64")
-	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} -mstackrealign -msse3 " CACHE INTERNAL "PhysX CXX")
+	SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections ${PHYSX_WARNING_DISABLES} -mstackrealign -msse3 " CACHE INTERNAL "PhysX CXX")
 ENDIF()
 
 # Build debug info for all configurations
diff --git a/physx/source/compiler/cmake/ios/CMakeLists.txt b/physx/source/compiler/cmake/ios/CMakeLists.txt
index 5605e9af..3d2fe6f0 100644
--- a/physx/source/compiler/cmake/ios/CMakeLists.txt
+++ b/physx/source/compiler/cmake/ios/CMakeLists.txt
@@ -26,7 +26,7 @@
 ## Copyright (c) 2008-2021 NVIDIA Corporation. All rights reserved.
 
 
-SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -ferror-limit=0 -Wall -Wextra -Werror -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
+SET(PHYSX_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -ferror-limit=0 -Wall -Wextra -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
 
 SET(CMAKE_SHARED_LINKER_FLAGS_CHECKED "")
 SET(CMAKE_SHARED_LINKER_FLAGS_PROFILE "")
diff --git a/physx/source/compiler/cmake/linux/CMakeLists.txt b/physx/source/compiler/cmake/linux/CMakeLists.txt
index aba53365..6246e488 100644
--- a/physx/source/compiler/cmake/linux/CMakeLists.txt
+++ b/physx/source/compiler/cmake/linux/CMakeLists.txt
@@ -28,8 +28,8 @@
 STRING(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWERCASE)
 
 #TODO: Fix warnings
-SET(CLANG_WARNINGS "-ferror-limit=0 -Wall -Wextra -Werror -Wno-alloca -Wno-anon-enum-enum-conversion -Wstrict-aliasing=2 -Weverything -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-gnu-anonymous-struct -Wno-undef -Wno-unused-function -Wno-nested-anon-types -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-format-nonliteral -Wno-implicit-fallthrough -Wno-undefined-reinterpret-cast -Wno-disabled-macro-expansion -Wno-zero-as-null-pointer-constant -Wno-shadow -Wno-unknown-warning-option -Wno-atomic-implicit-seq-cst -Wno-extra-semi-stmt")
-SET(GCC_WARNINGS "-Wall -Werror -Wno-invalid-offsetof -Wno-uninitialized")
+SET(CLANG_WARNINGS "-ferror-limit=0 -Wall -Wextra -Wno-alloca -Wno-anon-enum-enum-conversion -Wstrict-aliasing=2 -Weverything -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-gnu-anonymous-struct -Wno-undef -Wno-unused-function -Wno-nested-anon-types -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-format-nonliteral -Wno-implicit-fallthrough -Wno-undefined-reinterpret-cast -Wno-disabled-macro-expansion -Wno-zero-as-null-pointer-constant -Wno-shadow -Wno-unknown-warning-option -Wno-atomic-implicit-seq-cst -Wno-extra-semi-stmt")
+SET(GCC_WARNINGS "-Wall -Wno-invalid-offsetof -Wno-uninitialized")
 
 IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
 	# using Clang	  
diff --git a/physx/source/compiler/cmake/mac/CMakeLists.txt b/physx/source/compiler/cmake/mac/CMakeLists.txt
index 36799700..bfd13576 100644
--- a/physx/source/compiler/cmake/mac/CMakeLists.txt
+++ b/physx/source/compiler/cmake/mac/CMakeLists.txt
@@ -25,10 +25,18 @@
 ##
 ## Copyright (c) 2008-2021 NVIDIA Corporation. All rights reserved.
 
-SET(OSX_BITNESS "-arch x86_64")
-SET(CMAKE_OSX_ARCHITECTURES "x86_64")
+IF(PX_OUTPUT_ARCH STREQUAL "x86")
+	SET(OSX_BITNESS "-arch x86_64 -msse2")
+	SET(CMAKE_OSX_ARCHITECTURES "x86_64")
+ELSEIF(PX_OUTPUT_ARCH STREQUAL "arm")
+	SET(OSX_BITNESS "-arch arm64")
+	SET(CMAKE_OSX_ARCHITECTURES "arm64")
+ELSE()
+	SET(OSX_BITNESS "-arch x86_64 -arch arm64 -msse2")
+	SET(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
+ENDIF()
 
-SET(PHYSX_CXX_FLAGS "${OSX_BITNESS} -msse2 -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -Werror -ferror-limit=0 -Wall -Wextra -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
+SET(PHYSX_CXX_FLAGS "${OSX_BITNESS} -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -ferror-limit=0 -Wall -Wextra -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
 
 SET(CMAKE_SHARED_LINKER_FLAGS_CHECKED "")
 SET(CMAKE_SHARED_LINKER_FLAGS_PROFILE "")
diff --git a/physx/source/foundation/include/PsVecMath.h b/physx/source/foundation/include/PsVecMath.h
index 2718de2a..03949acb 100644
--- a/physx/source/foundation/include/PsVecMath.h
+++ b/physx/source/foundation/include/PsVecMath.h
@@ -56,6 +56,8 @@
 #define COMPILE_VECTOR_INTRINSICS 1
 #elif PX_IOS && PX_NEON
 #define COMPILE_VECTOR_INTRINSICS 1
+#elif PX_OSX && PX_NEON
+#define COMPILE_VECTOR_INTRINSICS 1
 #elif PX_SWITCH
 #define COMPILE_VECTOR_INTRINSICS 1
 #else
diff --git a/physx/source/foundation/src/unix/PsUnixFPU.cpp b/physx/source/foundation/src/unix/PsUnixFPU.cpp
index eb2cd050..5a223a10 100644
--- a/physx/source/foundation/src/unix/PsUnixFPU.cpp
+++ b/physx/source/foundation/src/unix/PsUnixFPU.cpp
@@ -33,7 +33,7 @@
 PX_COMPILE_TIME_ASSERT(8 * sizeof(uint32_t) >= sizeof(fenv_t));
 #endif
 
-#if PX_OSX
+#if PX_OSX && (PX_X86 || PX_X64)
 // osx defines SIMD as standard for floating point operations.
 #include <xmmintrin.h>
 #endif
@@ -47,7 +47,7 @@ physx::shdfnd::FPUGuard::FPUGuard()
 #elif PX_PS4
 	// not supported
 	PX_UNUSED(mControlWords);
-#elif PX_OSX
+#elif PX_OSX && (PX_X86 || PX_X64)
 	mControlWords[0] = _mm_getcsr();
 	// set default (disable exceptions: _MM_MASK_MASK) and FTZ (_MM_FLUSH_ZERO_ON), DAZ (_MM_DENORMALS_ZERO_ON: (1<<6))
 	_mm_setcsr(_MM_MASK_MASK | _MM_FLUSH_ZERO_ON | (1 << 6));
@@ -76,7 +76,7 @@ physx::shdfnd::FPUGuard::~FPUGuard()
 // not supported unless ARM_HARD_FLOAT is enabled.
 #elif PX_PS4
 // not supported
-#elif PX_OSX
+#elif PX_OSX && (PX_X86 || PX_X64)
 	// restore control word and clear exception flags
 	// (setting exception state flags cause exceptions on the first following fp operation)
 	_mm_setcsr(mControlWords[0] & ~_MM_EXCEPT_MASK);
@@ -92,7 +92,7 @@ PX_FOUNDATION_API void physx::shdfnd::enableFPExceptions()
 #if PX_LINUX && !defined(__EMSCRIPTEN__)
 	feclearexcept(FE_ALL_EXCEPT);
 	feenableexcept(FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW);
-#elif PX_OSX
+#elif PX_OSX && (PX_X86 || PX_X64)
 	// clear any pending exceptions
 	// (setting exception state flags cause exceptions on the first following fp operation)
 	uint32_t control = _mm_getcsr() & ~_MM_EXCEPT_MASK;
@@ -108,7 +108,7 @@ PX_FOUNDATION_API void physx::shdfnd::disableFPExceptions()
 {
 #if PX_LINUX && !defined(__EMSCRIPTEN__)
 	fedisableexcept(FE_ALL_EXCEPT);
-#elif PX_OSX
+#elif PX_OSX && (PX_X86 || PX_X64)
 	// clear any pending exceptions
 	// (setting exception state flags cause exceptions on the first following fp operation)
 	uint32_t control = _mm_getcsr() & ~_MM_EXCEPT_MASK;
diff --git a/physx/source/geomutils/include/GuSIMDHelpers.h b/physx/source/geomutils/include/GuSIMDHelpers.h
index caa8e5a6..733eca34 100644
--- a/physx/source/geomutils/include/GuSIMDHelpers.h
+++ b/physx/source/geomutils/include/GuSIMDHelpers.h
@@ -72,7 +72,7 @@ namespace Gu
 			const QuatV qV = V4LoadU(&q.x);
 			Vec3V column0V, column1V, column2V;
 			QuatGetMat33V(qV, column0V, column1V, column2V);
-#if defined(PX_SIMD_DISABLED) || PX_ANDROID || (PX_LINUX && (PX_ARM || PX_A64)) || (PX_UWP && (PX_ARM || PX_A64))
+#if defined(PX_SIMD_DISABLED) || PX_ANDROID || (PX_LINUX && (PX_ARM || PX_A64)) || (PX_UWP && (PX_ARM || PX_A64)) || (PX_OSX && PX_A64)
 			V3StoreU(column0V, column0);
 			V3StoreU(column1V, column1);
 			V3StoreU(column2V, column2);
diff --git a/physx/source/physxextensions/src/serialization/SnSerialUtils.cpp b/physx/source/physxextensions/src/serialization/SnSerialUtils.cpp
index 282b9810..6fdfd8f6 100644
--- a/physx/source/physxextensions/src/serialization/SnSerialUtils.cpp
+++ b/physx/source/physxextensions/src/serialization/SnSerialUtils.cpp
@@ -39,7 +39,7 @@ using namespace physx;
 namespace
 {
 
-#define SN_NUM_BINARY_PLATFORMS 16
+#define SN_NUM_BINARY_PLATFORMS 17
 const PxU32 sBinaryPlatformTags[SN_NUM_BINARY_PLATFORMS] =
 {
 	PX_MAKE_FOURCC('W','_','3','2'),
@@ -58,6 +58,7 @@ const PxU32 sBinaryPlatformTags[SN_NUM_BINARY_PLATFORMS] =
 	PX_MAKE_FOURCC('L','A','6','4'),
 	PX_MAKE_FOURCC('W','A','3','2'),
 	PX_MAKE_FOURCC('W','A','6','4'),
+	PX_MAKE_FOURCC('M','A','6','4'),
 };
 
 const char* sBinaryPlatformNames[SN_NUM_BINARY_PLATFORMS] =
@@ -78,6 +79,7 @@ const char* sBinaryPlatformNames[SN_NUM_BINARY_PLATFORMS] =
 	"linuxaarch64",
 	"uwparm",
 	"uwparm64",
+	"macaarch64"
 };
 
 }
@@ -118,6 +120,8 @@ PxU32 getBinaryPlatformTag()
 	return sBinaryPlatformTags[14];
 #elif PX_UWP && PX_A64
 	return sBinaryPlatformTags[15];
+#elif PX_OSX && PX_A64
+	return sBinaryPlatformTags[16];
 #else
 	#error Unknown binary platform
 #endif
diff --git a/pxshared/include/foundation/PxPreprocessor.h b/pxshared/include/foundation/PxPreprocessor.h
index 12d6147f..4a7d0e93 100644
--- a/pxshared/include/foundation/PxPreprocessor.h
+++ b/pxshared/include/foundation/PxPreprocessor.h
@@ -100,10 +100,15 @@ Operating system defines, see http://sourceforge.net/p/predef/wiki/OperatingSyst
 #define PX_ANDROID 1
 #elif defined(__linux__) || defined (__EMSCRIPTEN__) // note: __ANDROID__ implies __linux__
 #define PX_LINUX 1
-#elif defined(__APPLE__) && (defined(__arm__) || defined(__arm64__))
-#define PX_IOS 1
 #elif defined(__APPLE__)
-#define PX_OSX 1
+	#include <TargetConditionals.h>
+	#if TARGET_OS_IPHONE && TARGET_OS_MACCATALYST
+		#define PX_OSX 1
+	#elif TARGET_OS_IPHONE
+		#define PX_IOS 1
+	#else
+		#define PX_OSX 1
+	#endif
 #elif defined(__ORBIS__)
 #define PX_PS4 1
 #elif defined(__NX__)
