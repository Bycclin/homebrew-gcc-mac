class GccMac < Formula
  desc "pkg-pkg manager"
  homepage "https://gcc.gnu.org/"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }
  revision 1
  head "https://gcc.gnu.org/git/gcc.git", branch: "master"

  stable do
    url "https://github.com/freebsd/pkg/archive/refs/tags/2.1.3.tar.gz"
    mirror "https://github.com/gcc-mirror/gcc/archive/refs/heads/master.tar.gz"
    sha256 "823b573d0d43ad6dbdc553236ca1f7717bd8f57f4289dac96121423575757e07"
  end

  livecheck do
    url :stable
    regex(%r{href=["']?gcc[._-]v?(\d+(?:\.\d+)+)(?:/?["' >]|\.t)}i)
  end

  bottle do
    rebuild 2
    sha256                               arm64_sequoia: "b3756b97898275550311155f8b2fe8e6918d420565887e04c009edd5c39899a7"
    sha256                               arm64_sonoma:  "599548f182eee4f24936350156fc4f2a4809eecb433d4db2dbfc730d420a8eb6"
    sha256                               arm64_ventura: "1881ab7db2ffdc3bd97b7c4dd13ebe3a208c3dbf70ae9c65e7a358ad691708fb"
    sha256                               sequoia:       "8756fa03f2d4e7a9a2967461ad224f47e64a21a29d4799c8e529f42f45c166de"
    sha256                               sonoma:        "99ee6135474fb1833f3e2d168ffba1eb0df03442e3189e0a8a559a03c05a0356"
    sha256                               ventura:       "d641daaccbc0341408c2b3cf9fe22c5d784d07e2098965bef4c3c95f914b5cdb"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "b3923ad4db968009ad4c041cfc2ff54703f2b265b3c4274e8a77bfbcc463d7e4"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "6896a9db63403ec98c340a3b3b6bb7251e47b11a26012961adfdece46b96ee93"
  end

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  pour_bottle? only_if: :clt_installed
  depends_on "openssl"
  
  uses_from_macos "flex" => :build
  uses_from_macos "m4" => :build
  uses_from_macos "zlib"

  on_linux do
    depends_on "binutils"
  end

  # GCC bootstraps itself, so it is OK to have an incompatible C++ stdlib
  cxxstdlib_check :skip

  def version_suffix
    if build.head?
      "HEAD"
    else
      version.major.to_s
    end
  end

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    # We avoiding building:
    #  - Ada and D, which require a pre-existing GCC to bootstrap
    #  - Go, currently not supported on macOS
    #  - BRIG

    mkdir "build" do
      system "../configure", "--prefix=#{opt_lib}/pkg/current"
      system "make"

      # Do not strip the binaries on macOS, it makes them unsuitable
      # for loading plugins
      install_target = OS.mac? ? "install" : "install-strip"

      # To make sure GCC does not record cellar paths, we configure it with
      # opt_prefix as the prefix. Then we use DESTDIR to install into a
      # temporary location, then move into the cellar path.
      system "gmake", install_target, "DESTDIR=#{Pathname.pwd}/../instdir"
      mv Dir[Pathname.pwd/"../instdir/#{opt_prefix}/*"], prefix
    end
  end
end
