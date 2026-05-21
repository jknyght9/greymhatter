#!/bin/bash
# export-ova.sh - Convert QEMU raw disk to VMware-compatible OVA
#
# Usage: export-ova.sh <input_dir> <vm_name> <arch> <cpus> <memory_mb>
#
# This script:
# 1. Converts raw disk to streamOptimized VMDK
# 2. Generates an OVF descriptor from template
# 3. Computes SHA256 manifest
# 4. Packages everything into an OVA (tar)

set -euo pipefail

INPUT_DIR="$1"
VM_NAME="$2"
ARCH="$3"
CPUS="$4"
MEMORY_MB="$5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${INPUT_DIR}/../ova-${ARCH}"
DISK_RAW=$(find "$INPUT_DIR" -name "*.raw" -o -name "${VM_NAME}*" | head -1)

if [[ -z "$DISK_RAW" ]]; then
  echo "ERROR: No raw disk found in $INPUT_DIR"
  ls -la "$INPUT_DIR"
  exit 1
fi

echo "Input disk: $DISK_RAW"
mkdir -p "$OUTPUT_DIR"

# --- Step 1: Convert to streamOptimized VMDK ---
echo "Converting raw disk to VMDK..."
VMDK_FILE="${OUTPUT_DIR}/${VM_NAME}-${ARCH}-disk1.vmdk"
qemu-img convert -f raw -O vmdk -o subformat=streamOptimized "$DISK_RAW" "$VMDK_FILE"
echo "VMDK created: $VMDK_FILE"

# Get disk size for OVF
DISK_SIZE_BYTES=$(stat -c%s "$DISK_RAW" 2>/dev/null || stat -f%z "$DISK_RAW")
VMDK_SIZE_BYTES=$(stat -c%s "$VMDK_FILE" 2>/dev/null || stat -f%z "$VMDK_FILE")

# --- Step 2: Generate OVF descriptor ---
echo "Generating OVF descriptor..."
OVF_FILE="${OUTPUT_DIR}/${VM_NAME}-${ARCH}.ovf"

# Hardware version 17 = ESXi 7.0+ / Workstation 15.5+ / Fusion 11.5+
# (vmx-20 ships from Workstation 17 / Fusion 13 but ESXi 7 rejects it as
# "Unsupported hardware family". Stay at 17 for broad compatibility.)
cat > "$OVF_FILE" << OVFEOF
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:cim="http://schemas.dmtf.org/wbem/wscim/1/common"
          xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData"
          xmlns:vmw="http://www.vmware.com/schema/ovf"
          xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <References>
    <File ovf:href="${VM_NAME}-${ARCH}-disk1.vmdk" ovf:id="file1" ovf:size="${VMDK_SIZE_BYTES}"/>
  </References>
  <DiskSection>
    <Info>Virtual disk information</Info>
    <Disk ovf:capacity="${DISK_SIZE_BYTES}" ovf:capacityAllocationUnits="byte"
          ovf:diskId="vmdisk1" ovf:fileRef="file1"
          ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"
          ovf:populatedSize="${VMDK_SIZE_BYTES}"/>
  </DiskSection>
  <NetworkSection>
    <Info>The list of logical networks</Info>
    <Network ovf:name="NAT">
      <Description>NAT network</Description>
    </Network>
  </NetworkSection>
  <VirtualSystem ovf:id="${VM_NAME}">
    <Info>GreymHatter DFIR Distribution</Info>
    <Name>${VM_NAME}</Name>
    <OperatingSystemSection ovf:id="101" vmw:osType="fedora64Guest">
      <Info>The operating system installed</Info>
      <Description>Fedora 64-bit</Description>
    </OperatingSystemSection>
    <VirtualHardwareSection>
      <Info>Virtual hardware requirements</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>${VM_NAME}</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>vmx-17</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:AllocationUnits>hertz * 10^6</rasd:AllocationUnits>
        <rasd:Description>Number of Virtual CPUs</rasd:Description>
        <rasd:ElementName>${CPUS} virtual CPU(s)</rasd:ElementName>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>${CPUS}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>byte * 2^20</rasd:AllocationUnits>
        <rasd:Description>Memory Size</rasd:Description>
        <rasd:ElementName>${MEMORY_MB}MB of memory</rasd:ElementName>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>${MEMORY_MB}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Description>SATA Controller</rasd:Description>
        <rasd:ElementName>SATA Controller 0</rasd:ElementName>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>vmware.sata.ahci</rasd:ResourceSubType>
        <rasd:ResourceType>20</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:ElementName>Hard Disk 1</rasd:ElementName>
        <rasd:HostResource>ovf:/disk/vmdisk1</rasd:HostResource>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:Parent>3</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:AutomaticAllocation>true</rasd:AutomaticAllocation>
        <rasd:Connection>NAT</rasd:Connection>
        <rasd:Description>E1000e ethernet adapter</rasd:Description>
        <rasd:ElementName>Network Adapter 1</rasd:ElementName>
        <rasd:InstanceID>5</rasd:InstanceID>
        <rasd:ResourceSubType>E1000e</rasd:ResourceSubType>
        <rasd:ResourceType>10</rasd:ResourceType>
      </Item>
    </VirtualHardwareSection>
  </VirtualSystem>
</Envelope>
OVFEOF

echo "OVF created: $OVF_FILE"

# --- Step 3: Generate manifest ---
# Required format per OVF spec: SHA256(filename)= hash
echo "Computing SHA256 manifest..."
MF_FILE="${OUTPUT_DIR}/${VM_NAME}-${ARCH}.mf"
(
  cd "$OUTPUT_DIR"
  for f in "${VM_NAME}-${ARCH}.ovf" "${VM_NAME}-${ARCH}-disk1.vmdk"; do
    HASH=$(sha256sum "$f" | awk '{print $1}')
    printf 'SHA256(%s)= %s\n' "$f" "$HASH"
  done > "$(basename "$MF_FILE")"
)
echo "Manifest created: $MF_FILE"

# --- Step 4: Package OVA ---
# Use GNU tar's default format (not pax, not ustar). pax extension headers
# break some OVF parsers ("Line 1: Could not parse the document"), and ustar
# caps file sizes at 8 GiB which the VMDK regularly exceeds. The default on
# Linux GNU tar handles large files and is read correctly by ovftool/ESXi.
echo "Packaging OVA..."
OVA_FILE="${OUTPUT_DIR}/${VM_NAME}-${ARCH}.ova"
(
  cd "$OUTPUT_DIR"
  # OVA is a tar with OVF first, then manifest, then disk
  tar -cf "$(basename "$OVA_FILE")" \
    "${VM_NAME}-${ARCH}.ovf" \
    "${VM_NAME}-${ARCH}.mf" \
    "${VM_NAME}-${ARCH}-disk1.vmdk"
)

echo ""
echo "============================================"
echo "OVA created: $OVA_FILE"
echo "Size: $(du -h "$OVA_FILE" | cut -f1)"
echo "============================================"
echo ""
echo "Test by importing into VMware Workstation:"
echo "  File > Open > ${OVA_FILE}"
