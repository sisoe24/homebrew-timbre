# ============================================================================
# Formula/timbre.rb
# ============================================================================
# Homebrew formula for Timbre — ML-powered audio analyzer using CLAP.
#
# Tap:     brew tap sisoe24/timbre
# Install: brew install timbre
#
# Before publishing:
#   1. Push source to github.com/sisoe24/timbre and create a release tag.
#   2. Download the tarball and compute its SHA256:
#        curl -L https://github.com/sisoe24/timbre/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
#   3. Replace PLACEHOLDER_SHA256 below with the real value.
# ============================================================================

class Timbre < Formula
  include Language::Python::Virtualenv
  desc "ML-powered audio analyzer — intelligent sound tagging via CLAP"
  homepage "https://github.com/sisoe24/timbre"
  url "https://github.com/sisoe24/timbre/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "11f7ec9d40080f514a9857e146290d644f243011f45f122051f19ba230d5fd15"
  license "MIT"

  # ── System dependencies ────────────────────────────────────────────────────
  # ffmpeg: MP3 decoding and audio format support (required by librosa/audioread)
  # libsndfile: WAV/FLAC/OGG read-write (required by soundfile Python package)
  depends_on "ffmpeg"
  depends_on "libsndfile"
  depends_on "python@3.11"

  def install
    # macOS only for now (MPS / Apple Silicon path; Linux/CUDA support is separate)
    raise "Timbre currently only supports macOS." unless OS.mac?
    # ── Copy source into Homebrew's libexec ───────────────────────────────────
    # libexec keeps our files out of the global prefix so they don't conflict
    # with anything else the user has installed.
    libexec.install Dir["*"]

    # ── Create an isolated virtualenv ─────────────────────────────────────────
    venv = virtualenv_create(libexec/"venv")

    # ── PyTorch (platform-specific, installed before requirements.txt) ────────
    # Standard pip wheels for macOS include MPS support automatically.
    # torch >= 2.6.0 is required (CVE-2025-32434 torch.load safety fix).
    venv.pip_install "torch>=2.6.0", "torchaudio"

    # ── Remaining Python dependencies ─────────────────────────────────────────
    # Strip comments, blank lines, and the torch lines (already installed above)
    # so pip doesn't try to reinstall them.
    reqs = (libexec/"requirements.txt").readlines
              .reject { |l| l.strip.empty? || l.start_with?("#") || l =~ /^torch/ }
              .join
    (buildpath/"filtered_requirements.txt").write(reqs)
    venv.pip_install buildpath/"filtered_requirements.txt"

    # ── Wrapper script ─────────────────────────────────────────────────────────
    # Creates the `timbre` command in /usr/local/bin (or Homebrew's bin prefix).
    # Forwards all arguments directly to analyze.py.
    (bin/"timbre").write <<~EOS
      #!/bin/bash
      # Timbre — audio analysis CLI
      # Installed by Homebrew via sisoe24/timbre tap
      exec "#{libexec}/venv/bin/python" "#{libexec}/analyze.py" "$@"
    EOS
    chmod 0755, bin/"timbre"

    # ── Batch processing alias ────────────────────────────────────────────────
    (bin/"timbre-batch").write <<~EOS
      #!/bin/bash
      # Timbre batch processor — analyze an entire directory of audio files
      exec "#{libexec}/venv/bin/python" "#{libexec}/batch_process.py" "$@"
    EOS
    chmod 0755, bin/"timbre-batch"
  end

  def caveats
    <<~EOS
      Timbre is installed. On first run it will download the CLAP model
      (~1.2 GB) from HuggingFace Hub and cache it at:
        ~/.cache/huggingface/hub/

      This only happens once. Subsequent runs are instant.

      Usage:
        timbre path/to/file.wav
        timbre path/to/file.mp3 --output-dir ./out --markdown
        timbre-batch ./my_audio_folder/

      Docs: https://github.com/sisoe24/timbre
    EOS
  end

  test do
    # Smoke test: the CLI should respond to --help without errors
    assert_match "Usage:", shell_output("#{bin}/timbre --help")
    assert_match "Usage:", shell_output("#{bin}/timbre-batch --help")
  end
end
