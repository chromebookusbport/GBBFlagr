#!/bin/bash

# Force terminal compatibility
export TERM=xterm
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

# --- Configuration & Constants ---
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
CYAN=$'\e[36m'
BLUE=$'\e[34m'
PURPLE=$'\e[35m'
BBLUE=$'\e[1;34m'
GRAY=$'\e[90m'
WHITE=$'\e[97m'
NC=$'\e[0m'
BOLD=$'\e[1m'

# Randomly select a color for the logo on each run
LOGO_COLORS=("$RED" "$CYAN" "$GREEN" "$YELLOW" "$BLUE" "$BBLUE" "$PURPLE" "$WHITE")
RANDOM_COLOR=${LOGO_COLORS[$RANDOM % ${#LOGO_COLORS[@]}]}

# --- UI Functions ---
draw_logo() {
    echo -e "${RANDOM_COLOR}"
    echo "   █████████  ███████████  ███████████     ██████  ████                              "
    echo "  ███▒▒▒▒▒███▒▒███▒▒▒▒▒███▒▒███▒▒▒▒▒███   ███▒▒███▒▒███                              "
    echo " ███     ▒▒▒  ▒███    ▒███ ▒███    ▒███  ▒███ ▒▒▒  ▒███   ██████    ███████ ████████ "
    echo "▒███          ▒██████████  ▒██████████  ███████    ▒███  ▒▒▒▒▒███  ███▒▒███▒▒███▒▒███"
    echo "▒███    █████ ▒███▒▒▒▒▒███ ▒███▒▒▒▒▒███▒▒▒███▒     ▒███   ███████ ▒███ ▒███ ▒███ ▒▒▒ "
    echo "▒▒███  ▒▒███  ▒███    ▒███ ▒███    ▒███  ▒███      ▒███  ███▒▒███ ▒███ ▒███ ▒███     "
    echo " ▒▒█████████  ███████████  ███████████   █████     █████▒▒████████▒▒███████ █████    "
    echo "  ▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒     ▒▒▒▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒▒███▒▒▒▒▒     "
    echo "                                                                   ███ ▒███          "
    echo "                                                                  ▒▒██████           "
    echo "                                                                   ▒▒▒▒▒▒            "
    echo -e "${NC}"
}

echo -e "${GRAY}Initializing GBB Utility...${NC}"
sleep 0.3
clear

descriptions=(
    "Shorten dev screen timeout to 2 seconds"
    "[Unsupported] BIOS loads option ROMs from arbitrary PCI devices"
    "[Unsupported] Boot a non-ChromeOS kernel"
    "Force devmode"
    "Allow booting from external disk (USB) even if dev_boot_usb=0"
    "Disable firmware rollback protection"
    "Allow Enter key to trigger dev->tonorm screen"
    "Allow booting altfw OSes even if dev_boot_altfw=0"
    "[Unsupported] Running FAFT tests. May enable workarounds"
    "Disable EC software sync"
    "Default to booting altfw OS when dev screen times out"
    "Disable auxiliary firmware (auxfw) software sync"
    "Disable shutdown on lid closed"
    "[Unsupported] Allow full fastboot capability"
    "Recovery mode always assumes manual recovery"
    "Ignore FWMP"
    "Enable USB Device Controller"
    "Always sync CSE, even if it is same as CBFS CSE"
)

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: Please run with sudo.${NC}"
   exit 1
fi

FUTILITY_BIN=$(which futility 2>/dev/null || echo "/usr/bin/futility")

raw_output=$($FUTILITY_BIN gbb --get --flags 2>/dev/null)
current_hex=$(echo "$raw_output" | grep -i "flags:" | sed -n 's/.*flags: \(0x[0-9a-fA-F]*\).*/\1/p')
[[ -z "$current_hex" ]] && current_hex="0x00008071" # Fallback to common value

HW_WP="OFF"
[[ "$(crossystem wpsw_cur 2>/dev/null)" == "1" ]] && HW_WP="ENABLED"

sw_wp_raw=$(flashrom -p internal --wp-status 2>/dev/null)
SW_WP="OFF"
echo "$sw_wp_raw" | grep -q "write protect is enabled" && SW_WP="ENABLED"

hex_clean="${current_hex#0x}"
current_int=$((16#$hex_clean))
selected=()
num_options=${#descriptions[@]}
for ((i=0; i<num_options; i++)); do
    (( (current_int >> i) & 1 )) && selected+=("1") || selected+=("0")
done

trap "tput cnorm; clear; exit" SIGINT SIGTERM
tput civis; clear 

cursor=0
while true; do
    printf "\033[H"
    draw_logo
    echo -e "${GRAY}----------------------------------------------------------------${NC}"
    
    live_val=0
    for ((j=0; j<num_options; j++)); do
        [[ "${selected[$j]}" -eq 1 ]] && : $(( live_val |= (1 << j) ))
    done
    live_hex=$(printf "0x%08x" $live_val)

    for ((i=0; i<num_options; i++)); do
        if [[ $i -eq $cursor ]]; then
            line_color="${BOLD}${CYAN}"
            prefix="${line_color}> "
        else
            line_color="${NC}"
            prefix="  "
        fi

        if [[ "${selected[$i]}" -eq 1 ]]; then
            mark="[${GREEN}#${NC}${line_color}]"
        else
            mark="[ ]"
        fi
        
        printf "\033[K%b%b %s${NC}\n" "$prefix" "$mark" "${descriptions[$i]}"
    done
    
    echo -e "\n${BOLD}Flags: ${GREEN}${live_hex}${NC}"
    echo -e "${GRAY}HW-WP: $HW_WP | SW-WP: $SW_WP${NC}"
    echo -e "${YELLOW}(Space: Toggle | Enter: Proceed | Esc: Exit)${NC}"

    IFS= read -rsn1 key
    if [[ $key == $'\e' ]]; then
        read -rsn2 -t 0.1 next_chars
        if [[ -z "$next_chars" ]]; then clear; echo "Cancelled by user."; exit 0; fi
        case "$next_chars" in
            '[A') ((cursor--)); [ $cursor -lt 0 ] && cursor=$(($num_options - 1)) ;;
            '[B') ((cursor++)); [ $cursor -ge $num_options ] && cursor=0 ;;
        esac
    elif [[ $key == " " ]]; then
        [[ "${selected[$cursor]}" -eq 1 ]] && selected[$cursor]=0 || selected[$cursor]=1
    elif [[ $key == "" ]]; then 
        break
    fi
done

tput cnorm; clear

final_val=0
for ((i=0; i<num_options; i++)); do
    [[ "${selected[$i]}" -eq 1 ]] && : $(( final_val |= (1 << i) ))
done
final_hex=$(printf "0x%08x" $final_val)

draw_logo
echo -e "\nFinalizing Changes..."
echo -e "From: $current_hex"
echo -e "To:   ${GREEN}$final_hex${NC}\n"

if [[ "$HW_WP" == "ENABLED" ]]; then
    echo -e "${RED}ERROR: Hardware Write Protection (HW-WP) is ENABLED.${NC}"
    echo -e "Physical lock is active.${NC}:"
    echo -e "1. Unplug charger, open bottom cover."
    echo -e "2. Unplug the battery cable from the motherboard."
    echo -e "3. Plug charger back in and boot (with battery unplugged)."
    echo -e "4. Run this script again."
    exit 1
fi

if [[ "$SW_WP" == "ENABLED" ]]; then
    echo -e "${YELLOW}Software WP detected. Disabling...${NC}"
    flashrom -p internal --wp-disable >/dev/null 2>&1
    if flashrom -p internal --wp-status 2>/dev/null | grep -q "write protect is enabled"; then
         echo -e "${RED}Failed to disable Software WP. Is Hardware WP still on?${NC}"
         exit 1
    fi
fi

read -p "Write to firmware? (y/N) " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    if $FUTILITY_BIN gbb --set --flags="$final_hex"; then
        echo -e "${GREEN}SUCCESS: GBB flags updated!${NC}"
        echo "Reboot for changes to take effect."
    else
        echo -e "${RED}FAILURE: Write was blocked.${NC}"
        echo "This usually means the hardware is still locked."
    fi
else
    echo "No changes made."
fi
