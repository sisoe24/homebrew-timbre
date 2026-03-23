# homebrew-timbre

Homebrew tap for [Timbre](https://github.com/sisoe24/timbre) — an ML-powered audio analyzer that uses the [CLAP model](https://huggingface.co/laion/larger_clap_general) to tag and describe audio files intelligently.

## Install

```bash
brew tap sisoe24/timbre
brew install timbre
```

> **First run:** Timbre will download the CLAP model (~1.2 GB) from HuggingFace Hub and cache it at `~/.cache/huggingface/hub/`. This only happens once.

## Usage

```bash
# Analyze a single file
timbre analyze path/to/file.wav

# Save results as Markdown
timbre analyze path/to/file.mp3 --output-dir ./out --markdown

# Analyze a whole directory
timbre batch ./my_audio_folder/

# Inspect or switch vocabulary context
timbre vocab info
timbre vocab list
timbre vocab add ./config/vocabulary.yaml
timbre vocab use

# Validate generated JSON records
timbre validate --input ./out/json
```

## Requirements

- macOS 12.3+ (Monterey or later) with Apple Silicon (M1/M2/M3/M4)
- Homebrew handles all other dependencies (`ffmpeg`, `libsndfile`, Python 3.11)

## Source

[github.com/sisoe24/timbre](https://github.com/sisoe24/timbre)
