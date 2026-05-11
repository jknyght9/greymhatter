# Testing

## Automated Tests

The integration test suite validates forensic tools on a deployed VM:

```bash
# Run all tests
make test DEV_VM_IP=10.1.50.124

# Run specific test with verbose output
make test-manual DEV_VM_IP=10.1.50.124 TEST=test1

# Run on ARM64
make test-manual DEV_VM_IP=192.168.164.130 TEST=all
```

### Test 1: Memory Analysis

Validates Volatility 2 (Docker) and Volatility 3 against memory images.

| Check | Tool | Image |
|---|---|---|
| `windows.info` | Volatility 3 | 0zapftis (WinXP) |
| `windows.pslist` | Volatility 3 | 0zapftis |
| `imageinfo` | Volatility 2 | 0zapftis |
| `pslist` | Volatility 2 | 0zapftis |
| `windows.info` | Volatility 3 | DC01 (Win Server 2012 R2) |
| `windows.pslist` | Volatility 3 | DC01 |

### Test 2: Disk Analysis

Validates Sleuthkit and bulk_extractor against a USB disk image.

| Check | Tool |
|---|---|
| Partition table | `mmls` |
| File listing | `fls` |
| Image info | `img_stat` |
| Feature extraction | `bulk_extractor` |

### Test 3: Timeline Analysis

Validates the full timeline pipeline: E01 mount, hayabusa, log2timeline, and Timesketch import.

| Check | Tool |
|---|---|
| Timesketch startup | `docker compose up` |
| E01 mount | `ewfmount` |
| NTFS partition mount | `mount -t ntfs-3g` |
| EVTX timeline | Hayabusa |
| Plaso timeline | Log2timeline |
| Timeline import | `timesketch_importer` |

### Result Caching

Hayabusa and plaso outputs are cached between runs. If the output file exists, the test skips reprocessing and uses the cached result.

## Manual Testing

A comprehensive manual testing checklist is available at `tests/MANUAL_TESTING.md`. It covers:

- Desktop environment and login
- All CLI tools and shell functions
- Container services
- Network and security configuration
- Architecture-specific features

