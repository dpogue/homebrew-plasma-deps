class Physx < Formula
  desc "Scalable multi-platform physics SDK supporting a wide range of devices"
  homepage "https://developer.nvidia.com/physx-sdk"
  url "https://github.com/NVIDIAGameWorks/PhysX/archive/c3d5537bdebd6f5cd82fcaf87474b838fe6fd5fa.tar.gz"
  version "4.1.2.29873463"
  sha256 "03ec80617033365520d261e6b049f2576596ea41cc2097741cc3771aeda5f2b8"
  license "BSD-3-Clause"
  head "https://github.com/NVIDIAGameWorks/PhysX.git", branch: "4.1"

  bottle do
    root_url "https://github.com/dpogue/homebrew-plasma-deps/releases/download/physx-4.1.2.29873463"
    sha256 cellar: :any,                 big_sur:      "0a2344e6ff4c075b1ef29d3d60fa3fdd690ce13cea17d870340e69beee37b979"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "d4891538a578315e1bf75a3c8953bf8aa681a676ea63375ff96140a755eff01a"
  end

  depends_on "cmake" => :build

  # Patch to removed -Werror
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
index 36799700..97cb4c7f 100644
--- a/physx/source/compiler/cmake/mac/CMakeLists.txt
+++ b/physx/source/compiler/cmake/mac/CMakeLists.txt
@@ -28,7 +28,7 @@
 SET(OSX_BITNESS "-arch x86_64")
 SET(CMAKE_OSX_ARCHITECTURES "x86_64")
 
-SET(PHYSX_CXX_FLAGS "${OSX_BITNESS} -msse2 -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -Werror -ferror-limit=0 -Wall -Wextra -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
+SET(PHYSX_CXX_FLAGS "${OSX_BITNESS} -msse2 -std=c++11 -fno-rtti -fno-exceptions -ffunction-sections -fdata-sections -ferror-limit=0 -Wall -Wextra -fstrict-aliasing -Wstrict-aliasing=2 -Weverything -Wno-unknown-warning-option -Wno-documentation-deprecated-sync -Wno-documentation-unknown-command -Wno-float-equal -Wno-padded -Wno-weak-vtables -Wno-cast-align -Wno-conversion -Wno-missing-noreturn -Wno-missing-variable-declarations -Wno-shift-sign-overflow -Wno-covered-switch-default -Wno-exit-time-destructors -Wno-global-constructors -Wno-missing-prototypes -Wno-unreachable-code -Wno-unused-macros -Wno-unused-member-function -Wno-used-but-marked-unused -Wno-weak-template-vtables -Wno-deprecated -Wno-non-virtual-dtor -Wno-invalid-noreturn -Wno-return-type-c-linkage -Wno-reserved-id-macro -Wno-c++98-compat-pedantic -Wno-unused-local-typedef -Wno-old-style-cast -Wno-newline-eof -Wno-unused-private-field -Wno-undefined-reinterpret-cast -Wno-invalid-offsetof -Wno-zero-as-null-pointer-constant -Wno-atomic-implicit-seq-cst -gdwarf-2" CACHE INTERNAL "PhysX CXX")
 
 SET(CMAKE_SHARED_LINKER_FLAGS_CHECKED "")
 SET(CMAKE_SHARED_LINKER_FLAGS_PROFILE "")
