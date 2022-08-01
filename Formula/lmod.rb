class Lmod < Formula
  desc "Lua-based environment modules system to modify PATH variable"
  homepage "https://lmod.readthedocs.io"
  url "https://github.com/TACC/Lmod/archive/8.7.11.tar.gz"
  sha256 "7350627aeba9e03944b4131680a05e0341174aeaba43840e1ea30e7b3b4cfb74"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "67aef88b58e478f2b7f7d1abc2963387efc91b9ab9829c98c19bd7e6c6ed48cc"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "ef19f53f07427690ab3c4aa8e41810829a403664775ca7f72db9fa2a3f91bc57"
    sha256 cellar: :any_skip_relocation, monterey:       "954f9fc98df76fd85cb1233626ec1457e45ff652f58318976fa73c9fabadb864"
    sha256 cellar: :any_skip_relocation, big_sur:        "cdeaff95722d18e8db8347e18b9868a0cb8947a3138a08908905ca97acd15574"
    sha256 cellar: :any_skip_relocation, catalina:       "f4c7c6892b2245f8e2d280f5416e0d9c57ddf9aba9627f92e6ff969598d3dd4d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "50d237f06ca6389b6577e172e7c2d1616b3c8a9ba81b4b25337b0d36d7c42f9a"
  end

  depends_on "luarocks" => :build
  depends_on "pkg-config" => :build
  depends_on "lua"

  uses_from_macos "bc" => :build
  uses_from_macos "libxcrypt"
  uses_from_macos "tcl-tk"

  resource "luafilesystem" do
    url "https://github.com/keplerproject/luafilesystem/archive/v1_8_0.tar.gz"
    sha256 "16d17c788b8093f2047325343f5e9b74cccb1ea96001e45914a58bbae8932495"
  end

  resource "luaposix" do
    url "https://github.com/luaposix/luaposix/archive/refs/tags/v35.1.tar.gz"
    sha256 "1b5c48d2abd59de0738d1fc1e6204e44979ad2a1a26e8e22a2d6215dd502c797"
  end

  def install
    luaversion = Formula["lua"].version.major_minor
    luapath = libexec/"vendor"
    ENV["LUA_PATH"] = "?.lua;" \
                      "#{luapath}/share/lua/#{luaversion}/?.lua;" \
                      "#{luapath}/share/lua/#{luaversion}/?/init.lua"
    ENV["LUA_CPATH"] = "#{luapath}/lib/lua/#{luaversion}/?.so"

    resources.each do |r|
      r.stage do
        system "luarocks", "make", "--tree=#{luapath}"
      end
    end

    system "./configure", "--with-siteControlPrefix=yes", "--prefix=#{prefix}"
    system "make", "install"
  end

  def caveats
    <<~EOS
      To use Lmod, you should add the init script to the shell you are using.

      For example, the bash setup script is here: #{opt_prefix}/init/profile
      and you can source it in your bash setup or link to it.

      If you use fish, use #{opt_prefix}/init/fish, such as:
        ln -s #{opt_prefix}/init/fish ~/.config/fish/conf.d/00_lmod.fish
    EOS
  end

  test do
    sh_init = "#{prefix}/init/sh"

    (testpath/"lmodtest.sh").write <<~EOS
      #!/bin/sh
      . #{sh_init}
      module list
    EOS

    assert_match "No modules loaded", shell_output("sh #{testpath}/lmodtest.sh 2>&1")

    system sh_init
    output = shell_output("#{prefix}/libexec/spider #{prefix}/modulefiles/Core/")
    assert_match "lmod", output
    assert_match "settarg", output
  end
end
