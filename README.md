# CTF-Recon-Tool

## Description

The **CTF Recon Tool** is a Bash-based utility designed for reconnaissance tasks commonly performed in Capture The Flag (CTF) challenges and ethical hacking exercises. It provides an interactive menu-driven interface that automates common scans and enumeration steps. This script has been developed from my personal experince and may not be suitable in every cases, but if you are trying to solve any easy category challenge/room then it can surely help. Suggetions are always welcome :) , and will keep on updating the scripts to ensure all the basics steps are atleast covered in the script.

---

## Features

- Quick and full `nmap` scans
- Web directory brute-forcing (`gobuster`) with HTTP/HTTPS support
- Vulnerability scan using `nmap --script vuln`
- Manual FTP login interface
- WordPress scanning using `wpscan`
- SQL server login (only if credentials are found)
- Subdomain enumeration via `Sublist3r`
- More features to be added..

---

## Requirements

Ensure the following tools are installed:

- `nmap`
- `gobuster`
- `wpscan`
- `ftp`
- `sublist3r`

Install using:

```bash
sudo apt install nmap gobuster sublist3r ftp
sudo gem install wpscan
