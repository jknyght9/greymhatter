# Quick Start

After importing and booting the VM, log in with the default credentials:

```
Username: hatter
Password: H@tt3r123!
```

## 1. Explore the Dashboard

Open Firefox and navigate to `http://localhost:3000`. The Homepage dashboard provides links to all services.

## 2. Upload Your Evidence

Copy your memory dumps and disk images to the evidence directory. You can use the Samba share from another machine (see [Accessing the Samba Share](samba.md)) or copy files directly:

```bash
# Evidence directory
ls /opt/share/images/

# Example: copy from USB or network mount
cp /media/usb/evidence.E01 /opt/share/images/
cp /media/usb/memory.vmem /opt/share/images/
```

## 3. Start a Timeline Investigation

```bash
# Start Timesketch
starttimesketch

# Mount an E01 image
mountewf /opt/share/images/evidence.E01

# Check partition layout
mmls /mnt/ewf/ewf1

# Mount the NTFS partition (use offset from mmls)
mountpartition 1048576

# Generate a hayabusa timeline from EVTX files
hayabusa-timeline /mnt/evidence/Windows/System32/winevt/Logs case001

# Import the timeline into Timesketch
timesketch-import /opt/share/hayabusa/case001-hayabusa-timeline.csv
```

## 4. Analyze Memory

```bash
# Volatility 3
vol -f /opt/share/images/memory.vmem windows.info
vol -f /opt/share/images/memory.vmem windows.pslist
vol -f /opt/share/images/memory.vmem windows.netscan

# Volatility 2 (Docker)
vol2 -f /opt/share/images/memory.vmem imageinfo
```

## 5. Disk Analysis

```bash
# Partition layout
mmls /opt/share/images/disk.img

# File listing
fls -o 2048 /opt/share/images/disk.img

# Extract a file by inode
icat -o 2048 /opt/share/images/disk.img 16 > recovered_file.docx

# Bulk feature extraction
bulk_extractor -o /opt/share/bulk_output /opt/share/images/disk.img
```

## Next Steps

- [:octicons-arrow-right-24: Tools overview](../tools/overview.md)
- [:octicons-arrow-right-24: Shell functions reference](../tools/shell-functions.md)
- [:octicons-arrow-right-24: Configuration & paths](../configuration/credentials.md)
