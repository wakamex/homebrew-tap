# Rendered by packaging/homebrew/render-formula.py from the tagged Wsh source; do not edit.
class Wsh < Formula
  desc "Zsh with built-in autosuggestions, highlighting, history search and fast prompts"
  homepage "https://github.com/wakamex/wsh"
  url "https://github.com/wakamex/wsh/releases/download/v0.4.8/wsh-v0.4.8-source.tar.gz"
  sha256 "a731e85be0a5ad8c00e1d90f5a90174f15e07790feb0b9fc560ddbb6e2df29f0"
  license all_of: ["MIT", "MIT-Modern-Variant", "ISC", "GPL-2.0-only", "BSD-3-Clause"]

  depends_on "autoconf" => :build
  depends_on "coreutils" => :build
  depends_on "gnu-sed" => :build
  depends_on "gnu-tar" => :build
  depends_on "jq" => :build
  depends_on "jansson"
  depends_on "pcre2"

  uses_from_macos "python" => :build
  uses_from_macos "zsh" => :build
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  on_linux do
    depends_on "binutils" => :build
    depends_on "libcap"
  end

  # The pinned upstream Zsh source that Wsh patches, verified again by the build.
  resource "zsh-source" do
    url "https://github.com/zsh-users/zsh/archive/cad0d67c76e2be7371cf3526b79ea2581810d35a.tar.gz"
    sha256 "79120ee69dde051792ec548817126381331f26a7131244aab17d4d2cbb5b1819"
  end

  def install
    (buildpath/"build/cache").mkpath
    cp resource("zsh-source").fetch, buildpath/"build/cache/zsh-cad0d67c76e2be7371cf3526b79ea2581810d35a.tar.gz"
    # The build scripts use GNU coreutils, sed and tar options.
    %w[coreutils gnu-sed gnu-tar].each { |f| ENV.prepend_path "PATH", Formula[f].opt_libexec/"gnubin" }
    ENV["WSH_SOURCE_REVISION"] = "7caddc4314d7a530fb5e16f1c3c86e2f03916936"
    ENV["WSH_OFFLINE"] = "1"
    system "zsh", "./build/build-native-installation.zsh"
    bundles = Dir["bundles/*/share/wsh/manifest.json"].map { |manifest| File.expand_path("../../..", manifest) }
    odie "expected one built installation, found #{bundles.length}" if bundles.length != 1
    prefix.install Dir["#{bundles.first}/*"]
  end

  def caveats
    <<~EOS
      To make Wsh your login shell, register it and then select it:
        echo #{HOMEBREW_PREFIX}/bin/wsh | sudo tee -a /etc/shells
        chsh -s #{HOMEBREW_PREFIX}/bin/wsh
      Keep a terminal open until a new login works.
    EOS
  end

  test do
    assert_match "wsh #{version}", shell_output("#{bin}/wsh --wsh-version")
    # Through Homebrew's bin symlink, the shell must still find its resources and defaults.
    output = shell_output("#{HOMEBREW_PREFIX}/bin/wsh -ic 'print -r -- WSH:$WSH_VERSION:${+functions[compdef]}' 2>&1")
    assert_match "WSH:#{version}:1", output
    refute_match "integration unavailable", output
  end
end
