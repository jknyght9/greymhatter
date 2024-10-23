# GreymHatter

## Description

**GreymHatter** is a digital forensics and incident response distribution based on Fedora Linux. Primarily developed as a teaching platform, GreymHatter incorporates several forensics tools and shortcuts into one system, streamlining key processes like:

- Timeline development and analysis
- System log analysis
- Memory analysis
- Open Source Intelligence Gathering
- Cyber Threat Intelligence Utilization

## Legal

This platform was developed for instructional purposes and has not been tested in a production environment. The authors and maintainers of this project are not responsible for loss of data or productivity while using this product.

## Key Features

GreymHatter is built on the Fedora Workstation Linux distribution with the Gnome desktop environment. It uses the Docker container environment to house several applications. Furthermore, several forensic tools have been installed and configured. Tools installed include:

| Name              | Purpose                            | Type      | Run                    |
| ----------------- | ---------------------------------- | --------- | ---------------------- |
| cyberchef         | Self-hosted data operations site   | Container | http://localhost:8080  |
| homepage          | Self-hosted homepage for all sites | Container | http://localhost:3000  |
| maxmind-geoupdate | Updates GeoIP databases every day  | Container | -                      |
| spiderfoot        | OSINT gathering platform           | Container | http://localhost:5001  |
| timesketch        | Forensic timeline analysis tool    | Container | https://localhost      |
| yeti              | Cyber Threat Intelligence platform | Container | https://localhost:8888 |

Other tools included are:

| Name        | Purpose                                         |
| ----------- | ----------------------------------------------- |
| dfiq        | Digital Forensics Investigative Questions       |
| hayabusa    | Windows Event Log Analysis                      |
| sleuthkit   | For analyzing disk images                       |
| volatility3 | Memory analysis platform with JPCERT/CC symbols |

## Download

Download the latest OVF version here.

| Name         | Link                                                                                                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Image        | [https://cc-public.s3.us-east-1.amazonaws.com/GreymHatter-F40-Gnome-20241022.zip](https://cc-public.s3.us-east-1.amazonaws.com/GreymHatter-F40-Gnome-20241022.zip)       |
| Image Hashes | [https://cc-public.s3.us-east-1.amazonaws.com/GreymHatter-F40-Gnome-20241022.sha256](https://cc-public.s3.us-east-1.amazonaws.com/GreymHatter-F40-Gnome-20241022.sha256) |

Once downloaded, verify the zip file with the hash file using `sha256sum` or any other hashing program.

```shell
# On Linux
sha256sum -c GreymHatter-F40-Gnome-20241022.sha256

# Powershell
Get-Filehash GreymHatter-F40-Gnome-20241022.zip
Get-Content GreymHatter-F40-Gnome-20241022.sha256
```

Finally, unzip the file and import the OVF into your virtual machine software.

## Installation

If you choose to do a fresh installation, begin by installing Fedora Linux 40 with Gnome Desktop. Then fully update the system using

```shell
sudo dnf upgrade --refresh -y
```

Once completed, download this project and run the `setup.sh` script as the root user.

```shell
git clone https://github.com/jknyght9/greymhatter.git
cd greymhatter
bash setup.sh
```

This process takes a while as it is installing the various platforms, compiling volatility's symbol tables, and compiling sluethkit. Once completed, reboot the system.

## Default Login

The default login for the system, Timesketch, and Yeti is:

```text
username: hatter
password: H@tt3r123!
```

> **Note**: during the Samba (Windows share) setup, you will be asked to set a password. Remember this if you plan on using the Samba share on a Windows system.

## Screeshots

**Desktop**

![Desktop](./media/desktop.png)

**Fish Terminal with TMUX, BTOP, and CTOP**

![Terminal](./media/terminal.png)

**Homepage**

![Homepage](./media/homepage.png)

**Timesketch**

![Timesketch](./media/timesketch.png)

**Yeti Threat Intelligence**

![Yeti](./media/yeti.png)

**Spiderfoot**

![Spiderfoot](./media/spiderfoot.png)
