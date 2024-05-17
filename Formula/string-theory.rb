class StringTheory < Formula
  desc "Flexible modern C++ string library with type-safe formatting"
  homepage "https://github.com/zrax/string_theory"
  url "https://github.com/zrax/string_theory.git", tag: "3.8", revision: "39cdcdccd664e535c6c32141ffb36bb0bb2ac07d"
  license "MIT"
  head "https://github.com/zrax/string_theory.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/dpogue/plasma-deps"
    sha256 cellar: :any_skip_relocation, ventura:      "520f6f8339783fe35dde225044ebc25736bc1efd662be4bfbaab04ba36f0cf98"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "91b7393cac1320a432e98412fd8eb2ada83b7f455e42e508919a162ab0ad3ddf"
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
