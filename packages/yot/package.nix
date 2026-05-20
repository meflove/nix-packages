{
  lib,
  writeShellApplication,
  bun,
  yt-dlp,
  mpv,
  curl,
  coreutils,
  findutils,
}:
writeShellApplication {
  name = "yot";
  text = ''
    # yot - YouTube Translate: Watch YouTube videos with AI translation in mpv

    set -euo pipefail

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    # Default values
    TRANSLATE_LANG="ru"  # Language to translate TO
    ORIGINAL_AUDIO=true  # Include original audio as secondary track
    CACHE_DIR="''${XDG_CACHE_HOME:-''${HOME}/.cache}/yot"
    KEEP_FILES=false
    VERBOSE=false  # Verbose/debug mode

    # Create cache directory
    mkdir -p "$CACHE_DIR"

    usage() {
        cat << EOF
    Usage: yot [options] <youtube_url>

    Watch YouTube videos with AI translation in mpv player.

    Arguments:
        <youtube_url>              YouTube video link

    Options:
        -l, --lang <code>          Translation language (default: ru)
        -o, --only-translation     Only play translated audio (no original)
        -k, --keep-files           Keep downloaded files in cache
        -v, --verbose              Enable verbose/debug output
        -h, --help                 Show this help message

    Examples:
        yot https://youtube.com/watch?v=xxx
        yot -l en https://youtube.com/watch?v=xxx
        yot -o https://youtube.com/watch?v=xxx
        yot -v https://youtube.com/watch?v=xxx

    Supported languages: ru, en, de, fr, es, it, pt, zh, ja, ko, etc.

    EOF
        exit 0
    }

    log_info() {
        echo -e "''${GREEN}ℹ''${NC} $*"
    }

    log_error() {
        echo -e "''${RED}✗''${NC} $*" >&2
    }

    log_step() {
        echo -e "''${YELLOW}→''${NC} $*"
    }

    log_debug() {
        if [[ "$VERBOSE" == true ]]; then
            echo -e "''${YELLOW}[DEBUG]''${NC} $*" >&2
        fi
    }

    cleanup() {
        if [[ "$KEEP_FILES" != true ]]; then
            log_step "Cleaning up temporary files..."
            rm -f "$VIDEO_FILE" "$AUDIO_FILE" 2>/dev/null || true
        else
            log_info "Files kept in: $CACHE_DIR"
        fi
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--lang)
                TRANSLATE_LANG="$2"
                shift 2
                ;;
            -o|--only-translation)
                ORIGINAL_AUDIO=false
                shift
                ;;
            -k|--keep-files)
                KEEP_FILES=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                set -x  # Enable shell debugging
                shift
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                YOUTUBE_URL="$1"
                shift
                ;;
        esac
    done

    # Check if URL provided
    if [[ -z "''${YOUTUBE_URL:-}" ]]; then
        log_error "No YouTube URL provided"
        usage
    fi

    # Generate unique ID for this session
    SESSION_ID="$(date +%s%N)"
    VIDEO_FILE="$CACHE_DIR/video_$SESSION_ID.mp4"
    AUDIO_FILE="$CACHE_DIR/translation_$SESSION_ID.mp3"

    log_debug "Configuration:"
    log_debug "  Translation language: $TRANSLATE_LANG"
    log_debug "  Original audio: $ORIGINAL_AUDIO"
    log_debug "  Keep files: $KEEP_FILES"
    log_debug "  Cache directory: $CACHE_DIR"
    log_debug "  Session ID: $SESSION_ID"
    log_debug "  Video file: $VIDEO_FILE"
    log_debug "  Audio file: $AUDIO_FILE"

    log_info "YouTube Translate - Session ID: $SESSION_ID"
    echo

    # Step 1: Get translated audio
    log_step "Step 1/3: Getting translated audio..."
    log_info "Language: $TRANSLATE_LANG"

    log_debug "Running: bunx vot-cli --reslang=\"$TRANSLATE_LANG\" --output=\"$CACHE_DIR\" \"$YOUTUBE_URL\""

    if [[ "$VERBOSE" == true ]]; then
        VOT_OUTPUT=$(bunx vot-cli --reslang="$TRANSLATE_LANG" --output="$CACHE_DIR" "$YOUTUBE_URL" 2>&1 | tee /dev/stderr)
    else
        VOT_OUTPUT=$(bunx vot-cli --reslang="$TRANSLATE_LANG" --output="$CACHE_DIR" "$YOUTUBE_URL" 2>&1)
    fi

    AUDIO_LINK=$(echo "$VOT_OUTPUT" | grep -oP 'Audio Link.*: "\K[^"]+')
    log_debug "Extracted audio link: $AUDIO_LINK"

    if [[ -z "$AUDIO_LINK" ]]; then
        log_error "Failed to get translation link"
        log_debug "Full vot-cli output: $VOT_OUTPUT"
        exit 1
    fi

    # Find the downloaded audio file
    DOWNLOADED_AUDIO=$(find "$CACHE_DIR" -name "*.mp3" -type f -newermt "-1 minute" 2>/dev/null | head -n 1)

    if [[ -z "$DOWNLOADED_AUDIO" ]]; then
        # Try to download directly with spinner
        log_step "Downloading translation..."
        if [[ "$VERBOSE" == true ]]; then
            (
                curl -L -o "$AUDIO_FILE" "$AUDIO_LINK" --show-error
            ) &
        else
            (
                curl -L -o "$AUDIO_FILE" "$AUDIO_LINK" --silent --show-error
            ) &
        fi

        CURL_PID=$!
        while kill -0 $CURL_PID 2>/dev/null; do
            for s in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
                echo -ne "\r$s Downloading translation..."
                sleep 0.1
            done
        done

        wait $CURL_PID
        echo -ne "\r✓ Translation downloaded!    \n"
    else
        mv "$DOWNLOADED_AUDIO" "$AUDIO_FILE"
        log_info "Translation found in cache"
    fi

    if [[ ! -f "$AUDIO_FILE" ]]; then
        log_error "Failed to download translation audio"
        exit 1
    fi

    echo

    # Step 2: Download video with spinner
    log_step "Step 2/3: Downloading video..."

    if [[ "$VERBOSE" == true ]]; then
        (
            yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" \
                -o "$VIDEO_FILE" \
                --no-playlist \
                --restrict-filenames \
                --newline \
                --no-colors \
                "$YOUTUBE_URL"
        ) &
    else
        (
            yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" \
                -o "$VIDEO_FILE" \
                --no-playlist \
                --restrict-filenames \
                --newline \
                --no-warnings \
                --no-colors \
                --quiet \
                "$YOUTUBE_URL" &>/dev/null
        ) &
    fi

    # Show spinner while downloading
    YT_DLP_PID=$!
    while kill -0 $YT_DLP_PID 2>/dev/null; do
        for s in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
            echo -ne "\r$s Downloading video..."
            sleep 0.1
        done
    done

    # Wait for process to finish and check exit code
    wait $YT_DLP_PID
    YT_DLP_EXIT=$?

    if [[ $YT_DLP_EXIT -eq 0 ]] && [[ -f "$VIDEO_FILE" ]]; then
        echo -ne "\r✓ Download completed!    \n"
    else
        echo -ne "\r✗ Download failed!      \n"
        log_error "Failed to download video"
        exit 1
    fi
    echo

    # Step 3: Play in mpv
    log_step "Step 3/3: Starting mpv player..."
    echo

    # Build mpv command
    MPV_CMD=(mpv)

    if [[ "$ORIGINAL_AUDIO" == true ]]; then
        # Play with both audio tracks (translation first, original second)
        MPV_CMD+=(
            "$VIDEO_FILE"
            --audio-file="$AUDIO_FILE"
            --aid=2
            "--alang=ru,eng"
            --keep-open
        )
    else
        # Play only with translation (no original audio)
        MPV_CMD+=(
            "$VIDEO_FILE"
            --audio-file="$AUDIO_FILE"
            --aid=2
            --no-audio
            --keep-open
        )
    fi

    if [[ "$VERBOSE" == true ]]; then
        log_debug "MPV command: ''${MPV_CMD[*]}"
    fi

    # Trap cleanup on exit
    trap cleanup EXIT

    # Execute mpv
    log_info "Controls in mpv:"
    log_info "  # / _ - Switch audio tracks"
    log_info "  Space - Pause/Play"
    log_info "  q / ESC - Quit"
    echo

    "''${MPV_CMD[@]}"
  '';
  runtimeInputs = [
    bun
    yt-dlp
    mpv
    curl
    coreutils
    findutils
  ];
  meta = {
    description = "Watch YouTube videos with AI translation in mpv";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
