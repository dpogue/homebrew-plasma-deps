class StringTheory < Formula
  desc "Flexible modern C++ string library with type-safe formatting"
  homepage "https://github.com/zrax/string_theory"
  url "https://github.com/zrax/string_theory/archive/3.5.tar.gz"
  sha256 "de196ba0a552a513b6d9e10d7a4ccf2edd6982b26ad7b42c6a6ad9850f2b63a3"
  license "MIT"
  head "https://github.com/zrax/string_theory.git", branch: "master"

  bottle do
    root_url "https://github.com/dpogue/homebrew-plasma-deps/releases/download/string-theory-3.5"
    sha256 cellar: :any_skip_relocation, big_sur:      "2e5a12269da744357988b296d6016250c4b470586285ea9a7f670c3ae5031588"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "616221747a89623d840ec4e212c4c85e1e281cfa6e2b6e77375fc213a618f857"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make", "test"
    system "make", "install"
  end

  test do
    (testpath/"example.cpp").write <<~EOS
      #include <string_theory/string>
      #include <string_theory/stdio>

      int main(int argc, char *argv[])
      {
          ST::string greeting = ST_LITERAL("Hello");
          ST::printf("{}", greeting);

          return 0;
      }
    EOS

    system ENV.cxx, "example.cpp", "-std=c++11", "-I#{include}"
  end
end
