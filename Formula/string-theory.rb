class StringTheory < Formula
  desc "Flexible modern C++ string library with type-safe formatting"
  homepage "https://github.com/zrax/string_theory"
  url "https://github.com/zrax/string_theory/archive/3.6.tar.gz"
  sha256 "3610579ca34a15bcf1910a6f018a29a3946609d2983cc283491cf7f5c0dda562"
  license "MIT"
  head "https://github.com/zrax/string_theory.git", branch: "master"

  bottle do
    root_url "https://github.com/dpogue/homebrew-plasma-deps/releases/download/string-theory-3.6"
    sha256 cellar: :any_skip_relocation, big_sur:      "2c32b2c00b32a7b9868500c02dfbce0ea1d79c942535d42eb5fc7b0105ea3968"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ae57f4d892589fe409e9c870a0080e8a61b96dc460b65e6f3fee51d4ea2c5dec"
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
