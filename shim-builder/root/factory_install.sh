wspw_cur="$(crossystem wspw_cur)"

if [ "$wspw_cur" = "0" ]; then
    read -r -n 1 -s -p "press any key lmao"
    echo
    sudo flashrom --wp-disable &&
    sudo flashrom --wp-range 0 0 &&
    sudo flashrom --wp-range 0,0 &&
    vpd -s stable_device_secret_DO_NOT_SHARE="$(openssl rand -hex 32)"
    echo 'finished, not checking for errors, rebooting'
    sleep 2
    reboot
elif [ "$wspw_cur" = "1" ]; then
    echo "disable hwwp bro"
    sleep 5
    reboot
fi
