# Accessing the Samba Share

GreymHatter exposes `/opt/share` as a Samba (SMB/CIFS) file share, allowing you to transfer evidence files from your host machine to the VM.

## From Windows

1. Open **File Explorer**
2. In the address bar, type `\\<VM_IP>\share` and press ++enter++
3. Enter the credentials when prompted:
    - **Username**: `hatter`
    - **Password**: `H@tt3r123!`
4. Drag and drop your evidence files into the share

To map as a network drive:

1. Right-click **This PC** → **Map network drive**
2. Drive letter: choose any available letter
3. Folder: `\\<VM_IP>\share`
4. Check **Connect using different credentials**
5. Enter `hatter` / `H@tt3r123!`

## From Linux

```bash
# Mount the share
sudo mkdir -p /mnt/greymhatter
sudo mount -t cifs //<VM_IP>/share /mnt/greymhatter -o username=hatter,password='H@tt3r123!'

# Copy evidence
cp evidence.E01 /mnt/greymhatter/images/

# Unmount when done
sudo umount /mnt/greymhatter
```

Or use the file manager — most Linux desktops support `smb://<VM_IP>/share` in the address bar.

## From macOS

1. Open **Finder**
2. Press ++cmd+k++ (Connect to Server)
3. Enter `smb://<VM_IP>/share`
4. Enter `hatter` / `H@tt3r123!`

## Troubleshooting

If you cannot connect to the share, verify the Samba service is running on the VM:

```bash
sudo systemctl status smb
```

Check that the firewall allows Samba traffic — see [Firewall](firewall.md).
