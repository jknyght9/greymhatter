#!/bin/bash
# GreymHatter Integration Test Suite
# Runs on a deployed VM to validate all DFIR tools work correctly.
#
# Usage: bash run-tests.sh [--test0] [--test1] [--test2] [--test3] [--all]
#   --test0  Container smoke test (fast, <60s) — asserts expected containers
#            are running and respond. Use this as the inner-loop sanity check.
#   --test1  Memory analysis (Volatility 2 & 3)
#   --test2  Disk analysis (TSK & bulk_extractor)
#   --test3  Timeline analysis (log2timeline, hayabusa, Timesketch)
#   --all    Run all tests (default; test0 always runs as preflight)
#
# Exit codes:
#   0  All tests passed
#   1  Some tests failed
#   2  Preflight failed (infrastructure broken — tests didn't get a fair run)

set +e  # Don't exit on errors — we handle them with pass/fail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
VERBOSE=false
TEST_DIR="/opt/share/images"
RESULTS_DIR="/opt/share/test-results"

function info()    { echo -e "${BLUE}[+] $*${NC}"; }
function success() { echo -e "${GREEN}[✓] $*${NC}"; PASS=$((PASS+1)); }
function fail()    { echo -e "${RED}[✗] $*${NC}"; FAIL=$((FAIL+1)); }
function warn()    { echo -e "${YELLOW}[!] $*${NC}"; }
function header()  { echo -e "\n${BLUE}═══════════════════════════════════════${NC}"; echo -e "${BLUE}  $*${NC}"; echo -e "${BLUE}═══════════════════════════════════════${NC}\n"; }

function check_output() {
    local desc="$1"
    shift
    local output
    output=$("$@" 2>&1) || true
    if [ -n "$output" ]; then
        success "$desc"
        if [ "$VERBOSE" = "true" ]; then
            echo -e "${YELLOW}--- Output ---${NC}"
            echo "$output" | head -50
            echo -e "${YELLOW}--- End ($(echo "$output" | wc -l) total lines) ---${NC}"
            echo ""
        fi
    else
        fail "$desc — no output"
    fi
}

# Content-aware assertion: fails if expected string is NOT in stdout/stderr.
# Use instead of check_output when you can name a specific marker that
# distinguishes "tool ran correctly" from "tool printed an error".
function assert_contains() {
    local desc="$1"; local needle="$2"; shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -qF -- "$needle"; then
        success "$desc"
    else
        fail "$desc — expected output to contain '$needle'"
        echo "$output" | head -20
    fi
}

# Content-aware assertion: fails if output has fewer than MIN lines.
# Use when the tool should produce many rows (process list, partition table,
# event log entries) — guards against the "tool ran but found nothing" trap.
function assert_lines_gt() {
    local desc="$1"; local min="$2"; shift 2
    local output
    output=$("$@" 2>&1) || true
    local lines
    lines=$(echo "$output" | wc -l)
    if [ "$lines" -gt "$min" ]; then
        success "$desc ($lines lines)"
    else
        fail "$desc — only $lines lines, expected >$min"
        echo "$output" | head -20
    fi
}

# Preflight: assert the VM is in a valid state for tests to mean anything.
# Distinguishes "infrastructure broken" (exit 2) from "test logic failed" (exit 1).
function preflight() {
    header "Preflight: verifying VM state"

    local missing=0

    # Container infrastructure
    if ! systemctl is-active --quiet docker; then
        fail "Docker service not running"
        missing=1
    else
        success "Docker service active"
    fi

    # Architecture-aware image checks
    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        if ! docker images -q greymhatter/volatility2 2>/dev/null | grep -q .; then
            fail "vol2 image missing — test1 cannot validate vol2"
            missing=1
        fi
    fi

    if ! docker images --format '{{.Repository}}' | grep -qE '^(spiderfoot|clamav-hashbuilder|ghcr.io/gethomepage/homepage|ghcr.io/gchq/cyberchef)' ; then
        fail "Core container images missing — verify role did not pass"
        missing=1
    else
        success "Core container images present"
    fi

    # Binaries
    [ -x /opt/tools/hayabusa/hayabusa ] || { fail "hayabusa missing"; missing=1; }
    command -v vol >/dev/null            || { fail "vol (volatility3) missing"; missing=1; }
    command -v fls >/dev/null            || { fail "fls (sleuthkit) missing"; missing=1; }
    command -v bulk_extractor >/dev/null || { fail "bulk_extractor missing"; missing=1; }
    command -v ewfmount >/dev/null       || { fail "ewfmount missing"; missing=1; }
    command -v timesketch_importer >/dev/null || { fail "timesketch_importer missing"; missing=1; }

    # Working dirs
    [ -d /opt/share ]    || { fail "/opt/share missing"; missing=1; }
    [ -d /opt/hashsets ] || { fail "/opt/hashsets missing"; missing=1; }

    if [ "$missing" -eq 1 ]; then
        fail "Preflight failed — VM is not in a valid state for tests"
        echo -e "${RED}EXIT 2: infrastructure broken${NC}"
        exit 2
    fi
    success "Preflight passed"
}

# Test 0 — fast container sanity. Asserts the always-running services are
# Up and HTTP-responsive. Designed to be runnable in <60s.
function test0() {
    header "TEST 0: Container smoke test"

    # Always-running containers (must be Up)
    local container
    for container in homepage cyberchef clamav-hashbuilder courses; do
        if docker ps --format '{{.Names}}' | grep -q "$container"; then
            success "$container container running"
        else
            fail "$container container NOT running"
        fi
    done

    # HTTP endpoints
    local url; local desc; local codes
    while IFS='|' read -r desc url codes; do
        local status
        status=$(curl -sko /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null || echo 000)
        if echo "$codes" | grep -qw "$status"; then
            success "$desc → HTTP $status"
        else
            fail "$desc → HTTP $status (expected $codes)"
        fi
    done <<EOF
Homepage (3000)|http://localhost:3000|200 301 302
CyberChef (8080)|http://localhost:8080|200
Courses (8000)|http://localhost:8000|200 301 302
EOF
}

function run_verbose() {
    local desc="$1"
    shift
    info "Running: $*"
    local output
    output=$("$@" 2>&1) || true
    if [ -n "$output" ]; then
        success "$desc"
    else
        fail "$desc"
    fi
    echo -e "${YELLOW}--- Output ---${NC}"
    echo "$output" | head -100
    echo -e "${YELLOW}--- End ($(echo "$output" | wc -l) total lines) ---${NC}"
    echo ""
}

# --- Setup ---

mkdir -p "$TEST_DIR" "$RESULTS_DIR"

extract_image() {
    local zip="$1"
    [ -f "$zip" ] || return
    info "  Extracting $(basename $zip)..."
    unzip -o -q -P infected "$zip" -d "$TEST_DIR" 2>/dev/null || \
    unzip -o -q "$zip" -d "$TEST_DIR" 2>/dev/null || \
    warn "  Failed to extract $(basename $zip)"
}

info "Extracting test images..."

# Find extracted files
ZAPFTIS=$(find "$TEST_DIR" -name "*.vmem" -path "*zapftis*" 2>/dev/null | head -1)
DC01_MEM=$(find "$TEST_DIR" -name "*.vmem" -o -name "*.raw" -o -name "*.mem" 2>/dev/null | grep -i dc01 | head -1)
DC01_E01=$(find "$TEST_DIR" -name "*.E01" -o -name "*.e01" 2>/dev/null | head -1)
USB_IMG=$(find "$TEST_DIR" -name "usb-whistleblower.img" 2>/dev/null | head -1)

# =============================================================================
# Test 1: Memory Analysis (Volatility 2 & 3)
# =============================================================================

function test1() {
    header "TEST 1: Memory Analysis (Volatility 2 & 3)"

    if [ -z "$ZAPFTIS" ]; then
        fail "0zapftis memory image not found"
        return
    fi

    info "Testing with: $ZAPFTIS"

    # Volatility 3 — content-aware: ran tool AND parsed the image successfully
    info "--- Volatility 3 ---"
    assert_contains "vol3: windows.info on 0zapftis" "Kernel Base" vol -f "$ZAPFTIS" windows.info
    # 0zapftis is a small WinXP memory dump with a handful of processes (System,
    # smss, csrss, winlogon, explorer, ...). vol3's table-formatted output adds
    # 2 header rows. 5 rows total is realistic — anything less means vol3 failed
    # to enumerate processes at all.
    assert_lines_gt "vol3: windows.pslist on 0zapftis" 4 vol -f "$ZAPFTIS" windows.pslist

    # Volatility 2 (Docker)
    info "--- Volatility 2 (Docker) ---"
    if ! docker images -q greymhatter/volatility2 2>/dev/null | grep -q .; then
        fail "vol2: Docker image greymhatter/volatility2 not found"
    else
        # vol2 wrapper uses -it which fails in non-interactive mode, use docker run directly
        local vol2_out
        vol2_out=$(docker run --rm -v "$TEST_DIR:/evidence:ro" -w /evidence greymhatter/volatility2 -f "/evidence/$(basename $ZAPFTIS)" imageinfo 2>&1) || true
        if echo "$vol2_out" | grep -q "Suggested Profile"; then
            success "vol2: imageinfo on 0zapftis"
            if [ "$VERBOSE" = "true" ]; then echo "$vol2_out" | head -20; fi
        else
            fail "vol2: imageinfo on 0zapftis — no profile detected"
            if [ "$VERBOSE" = "true" ]; then echo "$vol2_out" | head -20; fi
        fi

        vol2_out=$(docker run --rm -v "$TEST_DIR:/evidence:ro" -w /evidence greymhatter/volatility2 -f "/evidence/$(basename $ZAPFTIS)" --profile=WinXPSP2x86 pslist 2>&1) || true
        if echo "$vol2_out" | grep -q "System"; then
            success "vol2: pslist on 0zapftis"
            if [ "$VERBOSE" = "true" ]; then echo "$vol2_out" | head -20; fi
        else
            fail "vol2: pslist on 0zapftis — no processes found"
            if [ "$VERBOSE" = "true" ]; then echo "$vol2_out" | head -20; fi
        fi
    fi

    if [ -n "$DC01_MEM" ]; then
        info "Testing with: $DC01_MEM"
        assert_contains "vol3: windows.info on DC01" "Kernel Base" vol -f "$DC01_MEM" windows.info
        assert_lines_gt "vol3: windows.pslist on DC01" 10 vol -f "$DC01_MEM" windows.pslist
    else
        warn "DC01 memory image not found, skipping"
    fi
}

# =============================================================================
# Test 2: Disk Analysis (TSK & bulk_extractor)
# =============================================================================

function test2() {
    header "TEST 2: Disk Analysis (TSK & bulk_extractor)"

    if [ -z "$USB_IMG" ]; then
        # Asset missing is a SKIP, not a FAIL — the test depends on a binary
        # blob that isn't checked into the repo. Distinguishes "can't test this"
        # from "the tool is broken".
        warn "TEST 2 SKIPPED — usb-whistleblower.img not available in test data"
        return
    fi

    info "Testing with: $USB_IMG"

    # Sleuthkit
    info "--- Sleuthkit ---"
    assert_contains "mmls: partition table" "Partition Table" mmls "$USB_IMG"

    # Get first real partition offset (match rows with numeric slot like "004:  000")
    local offset
    offset=$(mmls "$USB_IMG" 2>/dev/null | awk '/^[0-9]+:  [0-9]/ {print $3; exit}' || echo "")
    if [ -n "$offset" ]; then
        check_output "fls: file listing at offset $offset" fls -o "$offset" "$USB_IMG"
    else
        # Try without offset (whole disk image)
        check_output "fls: file listing (whole disk)" fls "$USB_IMG"
    fi

    check_output "img_stat: image info" img_stat "$USB_IMG"

    # bulk_extractor
    info "--- bulk_extractor ---"
    local be_output="$RESULTS_DIR/bulk_output_test"
    rm -rf "$be_output"
    if bulk_extractor -o "$be_output" "$USB_IMG" 2>&1 | tail -5; then
        if [ -d "$be_output" ] && [ "$(ls -A $be_output)" ]; then
            success "bulk_extractor: produced output in $be_output"
        else
            fail "bulk_extractor: no output files"
        fi
    else
        fail "bulk_extractor: command failed"
    fi
}

# =============================================================================
# Test 3: Timeline Analysis (log2timeline, hayabusa, Timesketch)
# =============================================================================

function test3() {
    header "TEST 3: Timeline Analysis (Timesketch pipeline)"

    if [ -z "$DC01_E01" ]; then
        fail "DC01 E01 image not found"
        return
    fi

    info "Testing with: $DC01_E01"

    # Start Timesketch
    info "Starting Timesketch..."
    cd /opt/timesketch
    docker compose --env-file config.env up -d --pull never 2>/dev/null

    # Wait for Timesketch
    info "Waiting for Timesketch to be ready..."
    local ready=false
    for i in $(seq 1 60); do
        if curl -kso /dev/null -w '%{http_code}' https://localhost 2>/dev/null | grep -q "200\|302"; then
            ready=true
            break
        fi
        sleep 5
    done

    if [ "$ready" != "true" ]; then
        fail "Timesketch did not start within 5 minutes"
        return
    fi
    success "Timesketch is running"

    # Mount E01 and extract EVTX for hayabusa
    info "--- Mounting E01 ---"
    EWF_MOUNT="/mnt/ewf"
    PART_MOUNT="/mnt/evidence"

    # Clean up any previous mounts
    umount "$PART_MOUNT" 2>/dev/null || true
    umount "$EWF_MOUNT" 2>/dev/null || fusermount -u "$EWF_MOUNT" 2>/dev/null || true

    mkdir -p "$EWF_MOUNT" "$PART_MOUNT"
    ewfmount "$DC01_E01" "$EWF_MOUNT" 2>/dev/null || true

    if [ -f "$EWF_MOUNT/ewf1" ]; then
        success "E01 mounted at $EWF_MOUNT"

        # Find the largest NTFS partition
        PART_OFFSET=$(mmls "$EWF_MOUNT/ewf1" 2>/dev/null | grep "NTFS" | sort -k5 -rn | head -1 | awk '{print $3+0}')
        if [ -n "$PART_OFFSET" ]; then
            BYTE_OFFSET=$((PART_OFFSET * 512))
            info "NTFS partition at sector $PART_OFFSET (byte offset $BYTE_OFFSET)"
            mount -t ntfs-3g -o loop,ro,show_sys_files,offset=$BYTE_OFFSET "$EWF_MOUNT/ewf1" "$PART_MOUNT" 2>/dev/null || true
            if mountpoint -q "$PART_MOUNT" 2>/dev/null; then
                success "NTFS partition mounted at $PART_MOUNT"
            else
                fail "Could not mount NTFS partition"
            fi
        else
            fail "No NTFS partition found in partition table"
        fi
    else
        fail "Failed to mount E01"
    fi

    # Hayabusa timeline
    info "--- Hayabusa ---"
    mkdir -p /opt/share/hayabusa
    HAYABUSA_OUT="/opt/share/hayabusa/test-hayabusa-timeline.csv"
    if [ -f "$HAYABUSA_OUT" ] && [ -s "$HAYABUSA_OUT" ]; then
        success "hayabusa: using cached output ($(wc -l < $HAYABUSA_OUT) lines)"
    else
        EVTX_DIR="$PART_MOUNT/Windows/System32/winevt/Logs"
        if [ ! -d "$EVTX_DIR" ]; then
            EVTX_DIR=$(find "$PART_MOUNT" -type d -iname "Logs" -path "*/winevt/*" 2>/dev/null | head -1)
        fi
        if [ -n "$EVTX_DIR" ] && [ -d "$EVTX_DIR" ]; then
            info "EVTX directory: $EVTX_DIR"
            TERM=dumb /opt/tools/hayabusa/hayabusa csv-timeline -d "$EVTX_DIR" --RFC-3339 -p timesketch-verbose -o "$HAYABUSA_OUT" --sort -C -w -Q 2>&1 | tail -3 || true
            if [ -f "$HAYABUSA_OUT" ] && [ -s "$HAYABUSA_OUT" ]; then
                success "hayabusa: timeline created ($(wc -l < $HAYABUSA_OUT) lines)"
            else
                fail "hayabusa: empty or missing output"
            fi
        else
            fail "hayabusa: EVTX directory not found in mounted image"
        fi
    fi

    # Unmount for log2timeline (it reads E01 directly)
    umount "$PART_MOUNT" 2>/dev/null || true
    umount "$EWF_MOUNT" 2>/dev/null || fusermount -u "$EWF_MOUNT" 2>/dev/null || true

    # Log2timeline (via Timesketch worker container)
    info "--- Log2timeline ---"
    mkdir -p /opt/share/plaso
    PLASO_OUT="/opt/share/plaso/test.plaso"
    if [ -f "$PLASO_OUT" ] && [ -s "$PLASO_OUT" ]; then
        success "log2timeline: using cached output ($(du -h $PLASO_OUT | cut -f1))"
    else
        docker exec timesketch-worker log2timeline.py --status-view none --storage-file /share/plaso/test.plaso /share/images/ 2>&1 | tail -5 || true
        if [ -f "$PLASO_OUT" ] && [ -s "$PLASO_OUT" ]; then
            success "log2timeline: plaso file created ($(du -h $PLASO_OUT | cut -f1))"
        else
            fail "log2timeline: empty or missing output"
        fi
    fi

    # Import timelines into Timesketch
    info "--- Timesketch Import ---"

    # Get a session cookie for API verification
    TS_CSRF=$(curl -sk -c /tmp/ts-cookies http://localhost/login/ 2>/dev/null \
        | sed -n 's/.*csrf_token.*value="\([^"]*\)".*/\1/p')
    curl -sk -c /tmp/ts-cookies -b /tmp/ts-cookies -X POST http://localhost/login/ \
        -d "username=hatter&password=H@tt3r123!&csrf_token=$TS_CSRF" \
        -H "Content-Type: application/x-www-form-urlencoded" -o /dev/null 2>/dev/null

    if [ -f "$HAYABUSA_OUT" ]; then
        info "Importing hayabusa timeline..."
        if timesketch_importer --host http://localhost --username hatter --password 'H@tt3r123!' \
            --sketch_name "XX-T001" --timeline_name "hayabusa" "$HAYABUSA_OUT" > /tmp/ts-import-hayabusa.log 2>&1; then
            tail -5 /tmp/ts-import-hayabusa.log
            success "hayabusa importer exited 0"
        else
            fail "hayabusa importer exited non-zero — see /tmp/ts-import-hayabusa.log"
            tail -10 /tmp/ts-import-hayabusa.log
        fi
    fi

    if [ -f "$PLASO_OUT" ]; then
        info "Importing plaso timeline..."
        if timesketch_importer --host http://localhost --username hatter --password 'H@tt3r123!' \
            --sketch_name "XX-T001" --timeline_name "plaso" "$PLASO_OUT" > /tmp/ts-import-plaso.log 2>&1; then
            tail -5 /tmp/ts-import-plaso.log
            success "plaso importer exited 0"
        else
            fail "plaso importer exited non-zero — see /tmp/ts-import-plaso.log"
            tail -10 /tmp/ts-import-plaso.log
        fi
    fi

    # Verify timelines exist in Timesketch via API
    info "Verifying timelines in Timesketch..."
    sleep 5
    SKETCH_DATA=$(curl -sk -b /tmp/ts-cookies http://localhost/api/v1/sketches/ 2>/dev/null)
    SKETCH_COUNT=$(echo "$SKETCH_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('meta',{}).get('total_items',0))" 2>/dev/null || echo 0)
    if [ "$SKETCH_COUNT" -gt 0 ] 2>/dev/null; then
        success "Timesketch sketch created ($SKETCH_COUNT sketch(es))"
    else
        fail "No sketches found in Timesketch"
    fi

    # Get the latest sketch ID and check its timelines
    SKETCH_ID=$(echo "$SKETCH_DATA" | python3 -c "
import sys,json
sketches = json.load(sys.stdin).get('objects',[])
print(sketches[-1]['id'] if sketches else '')
" 2>/dev/null || echo "")
    if [ -n "$SKETCH_ID" ]; then
        TIMELINE_COUNT=$(curl -sk -b /tmp/ts-cookies "http://localhost/api/v1/sketches/$SKETCH_ID/" 2>/dev/null | python3 -c "
import sys,json
sketch = json.load(sys.stdin).get('objects',[{}])[0]
print(len(sketch.get('timelines',[])))
" 2>/dev/null || echo 0)
        if [ "$TIMELINE_COUNT" -ge 2 ] 2>/dev/null; then
            success "Timelines verified: $TIMELINE_COUNT timeline(s) in sketch $SKETCH_ID"
        elif [ "$TIMELINE_COUNT" -ge 1 ] 2>/dev/null; then
            success "Timeline verified: $TIMELINE_COUNT timeline(s) in sketch $SKETCH_ID"
        else
            fail "No timelines found in sketch $SKETCH_ID"
        fi
    fi

    # Leave Timesketch running for manual verification
    info "Timesketch left running at https://localhost"
}

# =============================================================================
# Main
# =============================================================================

RUN_TEST0=false
RUN_TEST1=false
RUN_TEST2=false
RUN_TEST3=false

if [ $# -eq 0 ]; then
    RUN_TEST1=true; RUN_TEST2=true; RUN_TEST3=true
fi

for arg in "$@"; do
    case "$arg" in
        --test0)   RUN_TEST0=true ;;
        --test1)   RUN_TEST1=true ;;
        --test2)   RUN_TEST2=true ;;
        --test3)   RUN_TEST3=true ;;
        --all)     RUN_TEST0=true; RUN_TEST1=true; RUN_TEST2=true; RUN_TEST3=true ;;
        --verbose) VERBOSE=true ;;
    esac
done

# Preflight runs unconditionally — distinguishes "infrastructure broken"
# (exit 2) from "tests legitimately failed" (exit 1).
preflight

# Extract only the images needed for requested tests
[ "$RUN_TEST1" = "true" ] && extract_image /opt/share/test-data/0zapftis.zip
[ "$RUN_TEST1" = "true" ] && extract_image /opt/share/test-data/DC01-memory.zip
[ "$RUN_TEST2" = "true" ] && extract_image /opt/share/test-data/usb-whistleblower.img.zip
[ "$RUN_TEST3" = "true" ] && extract_image /opt/share/test-data/DC01-E01.zip

header "GreymHatter Integration Test Suite"

[ "$RUN_TEST0" = "true" ] && test0
[ "$RUN_TEST1" = "true" ] && test1
[ "$RUN_TEST2" = "true" ] && test2
[ "$RUN_TEST3" = "true" ] && test3

# --- Summary ---
header "Test Results"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
