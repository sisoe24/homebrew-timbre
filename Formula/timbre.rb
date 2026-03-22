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
  desc "ML-powered audio analyzer — intelligent sound tagging via CLAP"
  homepage "https://github.com/sisoe24/timbre"
  url "https://github.com/sisoe24/timbre/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "10b3a492ecb4ac07de416e8c83cecfb13f2ad18bccfe571302420dee81ddc524"
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
    libexec.install Dir["*"]

    # ── Create an isolated virtualenv directly via Python ────────────────────
    python = Formula["python@3.11"].opt_bin/"python3.11"
    system python, "-m", "venv", libexec/"venv"

    pip = libexec/"venv/bin/pip"
    system pip, "install", "--upgrade", "pip"

    # ── PyTorch (before requirements.txt to avoid version conflicts) ──────────
    system pip, "install", "torch>=2.6.0", "torchaudio"

    # ── Remaining Python dependencies ─────────────────────────────────────────
    # Strip comments, blank lines, and torch lines (already installed above).
    requirements = (libexec/"requirements.txt").readlines
    reqs = requirements.reject { |l| l.strip.empty? || l.start_with?("#") || l =~ /^torch/ }.join
    (buildpath/"filtered_requirements.txt").write(reqs)
    system pip, "install", "-r", buildpath/"filtered_requirements.txt"

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
