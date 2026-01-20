# Homebrew Formula for timeout command
# Save this as Formula/timeout.rb in your homebrew-timeout repository

class Timeout < Formula
  desc "C# implementation of the GNU timeout command"
  homepage "https://github.com/spgennard/cs-timeout"
  version "1.0.0"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/spgennard/cs-timeout/releases/download/v1.0.0/timeout-1.0.0-osx-arm64.tar.gz"
    sha256 "REPLACE_WITH_ARM64_SHA256"
  else
    url "https://github.com/spgennard/cs-timeout/releases/download/v1.0.0/timeout-1.0.0-osx-x64.tar.gz"
    sha256 "REPLACE_WITH_X64_SHA256"
  end

  def install
    bin.install "timeout"
  end

  test do
    # Test basic functionality
    assert_match "Usage:", shell_output("#{bin}/timeout --help 2>&1")
    
    # Test that it can run a simple command with timeout
    output = shell_output("#{bin}/timeout 1s echo 'test' 2>&1")
    assert_match "test", output
    
    # Test version output if available
    system "#{bin}/timeout", "--version"
  end
end