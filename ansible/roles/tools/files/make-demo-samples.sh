#!/usr/bin/env bash
# Build the before-and-after pair used in 4.2.2, on your own analysis host.
# Nothing here is malware. The only detection you will see is the EICAR test file,
# which exists so you can prove your scanner works without holding a real sample.
set -euo pipefail

# work somewhere you can delete afterwards
D=~/pe-demo
mkdir -p "$D"
cd "$D"

# a benign Windows binary that already ships on the image
cp /opt/tools/dfir-pstools/bins/bin/file.exe orig.exe

# the same program, compressed by a packer
# -f so a second run overwrites rather than failing on the existing file
upx -qf --best -o packed.exe orig.exe >/dev/null

# the EICAR test string, assembled in parts so this script is not itself detected
printf '%s%s%s' 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR' '-STANDARD-ANTIVIRUS-TEST-FILE' '!$H+H*' > eicar.com

# the rule from the slides, so you can run it rather than retype it
cat > upx.yar <<'YARA'
rule UPX_Packed_PE
{
    meta:
        description = "A PE carrying UPX section names"
    strings:
        $s0 = "UPX0"
        $s1 = "UPX1"
    condition:
        uint16(0) == 0x5A4D and all of them
}
YARA

# confirm what you just built
ls -l orig.exe packed.exe eicar.com upx.yar
