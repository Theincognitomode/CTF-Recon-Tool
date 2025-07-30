#!/bin/bash

# Simple CTF Recon Tool
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET=""
WEB_TARGET=""
WORDLIST="/usr/share/wordlists/dirb/common.txt"

banner() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Simple CTF Recon Tool made with lobe ;) ${NC}"
    echo -e "${BLUE}============================================${NC}"
}

set_target() {
    echo -e "${YELLOW}Enter target IP:${NC}"
    read TARGET
    echo -e "${GREEN}Target set to: $TARGET${NC}"
}

quick_scan() {
    if [ -z "$TARGET" ]; then
        echo -e "${RED}No target set!${NC}"
        return
    fi
    echo -e "${YELLOW}Running quick nmap scan on $TARGET...${NC}"
    nmap -sS -T4 --top-ports 1000 $TARGET
}

full_scan() {
    if [ -z "$TARGET" ]; then
        echo -e "${RED}No target set!${NC}"
        return
    fi
    echo -e "${YELLOW}Running full nmap scan on $TARGET...${NC}"
    nmap -sS -sV -O -A -T4 -p- $TARGET
}

web_scan() {
    echo -e "${YELLOW}Current web target: ${GREEN}${WEB_TARGET:-Not Set}${NC}"
    echo -e "${YELLOW}Do you want to set/change the web target? (y/n):${NC}"
    read CHANGE_WEB

    if [[ "$CHANGE_WEB" == "y" || "$CHANGE_WEB" == "Y" || -z "$WEB_TARGET" ]]; then
        echo -e "${YELLOW}Enter web target (IP or domain):${NC}"
        read NEW_WEB_TARGET
        if [ -n "$NEW_WEB_TARGET" ]; then
            WEB_TARGET="$NEW_WEB_TARGET"
        else
            echo -e "${RED}Invalid input. Aborting web scan.${NC}"
            return
        fi
    fi

    echo -e "${YELLOW}Do you want to add a port address to the target? (y/n):${NC}"
    read ADD_PORT

    if [[ "$ADD_PORT" == "y" || "$ADD_PORT" == "Y" ]]; then
        echo -e "${YELLOW}Enter web port (default 80):${NC}"
        read PORT
        PORT=${PORT:-80}
    else
        PORT="" 
    fi
    
    echo -e "${YELLOW}Choose protocol: [1] HTTP (default)  [2] HTTPS${NC}"
    read PROTOCOL_CHOICE
    if [[ "$PROTOCOL_CHOICE" == "2" ]]; then
        SCHEME="https"
    else
        SCHEME="http"
    fi

    echo -e "${YELLOW}Current wordlist: ${GREEN}$WORDLIST${NC}"
    echo -e "${YELLOW}Do you want to change the wordlist? (y/n):${NC}"
    read CHANGE_WORDLIST

    if [[ "$CHANGE_WORDLIST" == "y" || "$CHANGE_WORDLIST" == "Y" ]]; then
        echo -e "${YELLOW}Enter new wordlist path:${NC}"
        read NEW_WORDLIST
        if [[ -f "$NEW_WORDLIST" ]]; then
            WORDLIST="$NEW_WORDLIST"
            echo -e "${GREEN}Wordlist updated to: $WORDLIST${NC}"
        else
            echo -e "${RED}Invalid path! Using previous wordlist.${NC}"
        fi
    fi

    if [[ -n "$PORT" ]]; then
        URL="${SCHEME}://${WEB_TARGET}:${PORT}"
    else
        URL="${SCHEME}://${WEB_TARGET}"

    echo -e "${YELLOW}Running web directory scan on $URL ...${NC}"

    echo -e "${BLUE}[*] Starting Gobuster...${NC}"
    OUTPUT=$(gobuster dir -u "$URL" -w "$WORDLIST" 2>&1)

    if echo "$OUTPUT" | grep -q "certificate"; then
        echo -e "${RED}[!] SSL error detected. Retrying with --insecure flag...${NC}"
        gobuster dir -u "$URL" -w "$WORDLIST" --insecure
    else
        echo "$OUTPUT"
    fi
}

ftp_connect() {
    if [ -z "$TARGET" ]; then
        echo -e "${YELLOW}No target set yet.${NC}"
        echo -e "${YELLOW}Enter target IP for FTP connection:${NC}"
        read TARGET
    else
        echo -e "${YELLOW}Current target is: ${GREEN}$TARGET${NC}"
        echo -e "${YELLOW}Do you want to change the target? (y/n):${NC}"
        read CHANGE
        if [[ "$CHANGE" == "y" || "$CHANGE" == "Y" ]]; then
            echo -e "${YELLOW}Enter new target IP:${NC}"
            read TARGET
        fi
    fi

    echo -e "${YELLOW}Opening FTP connection to $TARGET...${NC}"
    echo -e "${GREEN}You can now manually enter username and password in the FTP shell.${NC}"
    ftp "$TARGET"
}


vuln_scan() {
    if [ -z "$TARGET" ]; then
        echo -e "${RED}No target set!${NC}"
        return
    fi
    echo -e "${YELLOW}Running vulnerability scan on $TARGET...${NC}"
    nmap --script vuln $TARGET
}

wpscan_scan() {
    echo -e "${YELLOW}Current web target: ${GREEN}${WEB_TARGET:-Not Set}${NC}"
    echo -e "${YELLOW}Do you want to change the web target? (y/n):${NC}"
    read CHANGE_WEB

    if [[ "$CHANGE_WEB" == "y" || "$CHANGE_WEB" == "Y" || -z "$WEB_TARGET" ]]; then
        echo -e "${YELLOW}Enter new WordPress target (domain or IP):${NC}"
        read NEW_WEB_TARGET
        if [[ -n "$NEW_WEB_TARGET" ]]; then
            WEB_TARGET="$NEW_WEB_TARGET"
        else
            echo -e "${RED}No valid target entered. Aborting WPScan.${NC}"
            return
        fi
    fi

    echo -e "${YELLOW}Choose scan type:${NC}"
    echo -e "${BLUE}1)${NC} Basic scan"
    echo -e "${BLUE}2)${NC} Enumerate plugins"
    echo -e "${BLUE}3)${NC} Enumerate users"
    echo -e "${BLUE}4)${NC} Full scan (plugins + users)"
    read SCAN_CHOICE

    ENUM_OPTIONS=""
    case $SCAN_CHOICE in
        2) ENUM_OPTIONS="--enumerate p" ;;
        3) ENUM_OPTIONS="--enumerate u" ;;
        4) ENUM_OPTIONS="--enumerate u,p" ;;
        *) ENUM_OPTIONS="" ;;
    esac

    echo -e "${YELLOW}Running WPScan on http://${WEB_TARGET} ...${NC}"
    wpscan --url "http://$WEB_TARGET" $ENUM_OPTIONS
}

sql_login() {
    echo -e "${YELLOW}[!] This should only be used if you have valid SQL username and password.${NC}"

    echo -e "${YELLOW}Use current target ($TARGET)? (y/n):${NC}"
    read USE_TARGET

    if [[ "$USE_TARGET" == "y" || "$USE_TARGET" == "Y" ]]; then
        SQL_HOST="$TARGET"
    else
        echo -e "${YELLOW}Enter SQL server IP or domain:${NC}"
        read SQL_HOST
        if [ -z "$SQL_HOST" ]; then
            echo -e "${RED}No host entered. Aborting.${NC}"
            return
        fi
    fi

    echo -e "${YELLOW}Enter SQL server port (default 3306):${NC}"
    read SQL_PORT
    SQL_PORT=${SQL_PORT:-3306}

    echo -e "${YELLOW}Enter SQL username:${NC}"
    read SQL_USER

    echo -e "${YELLOW}Enter SQL password (input hidden):${NC}"
    read -s SQL_PASS

    echo -e "${YELLOW}Attempting to connect to MySQL on $SQL_HOST:$SQL_PORT as $SQL_USER...${NC}"

    mysql -h "$SQL_HOST" -P "$SQL_PORT" -u "$SQL_USER" -p"$SQL_PASS"
}

smb_enum() {
    echo -e "${YELLOW}Enter SMB target IP:${NC}"
    read SMB_TARGET
    enum4linux -a "$SMB_TARGET"
}

subdomain_enum() {
    echo -e "${YELLOW}Enter the domain name for subdomain enumeration:${NC}"
    read DOMAIN

    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}No domain entered. Aborting.${NC}"
        return
    fi

    echo -e "${YELLOW}Running Sublist3r on domain: $DOMAIN${NC}"
    sublist3r -d "$DOMAIN"
}


show_menu() {
    echo
    echo -e "${GREEN}Current target: ${YELLOW}$TARGET${NC}"
    echo -e "${GREEN}Web target: ${YELLOW}${WEB_TARGET:-Not Set}${NC}"
    echo -e "${BLUE}1)${NC} Set target"
    echo -e "${BLUE}2)${NC} Quick scan (top 1000 ports)"
    echo -e "${BLUE}3)${NC} Full scan (all ports + service detection)"
    echo -e "${BLUE}4)${NC} Web directory scan"
    echo -e "${BLUE}5)${NC} Try FTP login (manual)"
    echo -e "${BLUE}6)${NC} Vulnerability scan"
    echo -e "${BLUE}7)${NC} WPScan (WordPress vulnerability scanner)"
    echo -e "${BLUE}8)${NC} Connect to SQL Server (only use when you have username & password)"
    echo -e "${BLUE}9)${NC} SMB Enumeration"
    echo -e "${BLUE}10)${NC} Subdomain Enumeration (Sublist3r)"
    echo -e "${BLUE}0)${NC} Exit"
    echo -e "${YELLOW}Choose option:${NC}"
}

main() {
    banner

    while true; do
        show_menu
        read choice

        case $choice in
            1) set_target ; continue;;
            2) quick_scan ;;
            3) full_scan ;;
            4) web_scan ;;
	    5) ftp_connect ;;
            6) vuln_scan ;;
	    7) wpscan_scan ;;
	    8) sql_login;;
	    9) smb_enum;;
	    10) subdomain_enum;;
            0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac

        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}Running as root - all scans available${NC}"
else
    echo -e "${YELLOW}Note: Some scans work better with sudo${NC}"
fi

main
