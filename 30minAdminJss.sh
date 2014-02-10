#!/bin/bash
##############
# This script will give a user 30 minutes of Admin level access, from Jamf's self service.
# At the end of the 30 minutes it will then call a jamf policy with a manual trigger. 
# Remove the users admin rights and disable the plist file this creates and activites.
# The removal script is 30minAdminjssRemoved.sh
#
# This was writen by
# Kyle Brockman
# While working for Univeristy Information Technology Servives
# at the Univeristy of Wisconsin Milwaukee
##############

######
U=`who | grep console | awk '{print $1}'`
CD="/Applications/Utilities/CocoaDialog.app/Contents/MacOS/CocoaDialog"
CDI="/Applications/Utilities/CocoaDialog.app/Contents/Resources"
######

if [[ ! -f /var/.uitsAdminAgreement ]]; then

    agreement=`$CD standard-inputbox --title "Admin Agreement" --float --informative-text "A base image was installed with software supported by UITS and that, in the event of problems, the base image will be reinstalled; overwriting any software I have installed or configuration changes I have made. I understand that NO locally saved data on the machine will be backed up and restored by UITS if a base image reinstall is required. I will only install software properly licensed for use by the University and its employees and will not install any unlicensed software on this computer. I will not attempt to disable/uninstall any software that has been put into place to maintain security (i.e. automatic updates, antivirus application, etc.) If you agree with the above, then please type in agree all in lowercase."`

    echo $agreement

    if [[ $agreement = "1 agree" ]]; then

        echo "Client has agreed."

        echo $U >> /var/.uitsAdminAgreement

        touch /Library/Application\ Support/JAMF/Receipts/TempAdminAuth.dmg

    else

        echo "Client did not agree"

        exit 0

    fi

else

    atItAgain=`$CD ok-msgbox --title "Temporary Admin" --float --text "Temporary Admin for 30 mintues" --informative-text "You will now have admin rights to this machine for 30 mintures."`

    if [[ $atItAgain = "1" ]]; then

        echo "Client clicked ok"

    else

        echo "Client clicked canel"
        exit 0

    fi

fi

# Place launchD plist to call JSS policy to remove admin rights.
#####
echo "<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict>
	<key>Disabled</key>
	<true/>
	<key>Label</key> 
	<string>edu.uwm.uits.brockma9.adminremove</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/sbin/jamf</string>
		<string>policy</string>
		<string>-trigger</string>
		<string>adminremove</string>
	</array>
	<key>StartInterval</key>
	<integer>1800</integer> 
</dict> 
</plist>" > /Library/LaunchDaemons/edu.uwm.uits.brockma9.adminremove.plist
#####

#set the permission on the file just made.
chown root:wheel /Library/LaunchDaemons/edu.uwm.uits.brockma9.adminremove.plist
chmod 644 /Library/LaunchDaemons/edu.uwm.uits.brockma9.adminremove.plist
defaults write /Library/LaunchDaemons/edu.uwm.uits.brockma9.adminremove.plist disabled -bool false

# load the removal plist timer. 
launchctl load -w /Library/LaunchDaemons/edu.uwm.uits.brockma9.adminremove.plist

# build log files in var/uits
mkdir /var/uits
TIME=`date "+Date:%m-%d-%Y TIME:%H:%M:%S"`
echo $TIME " by " $U >> /var/uits/30minAdmin.txt

echo $U >> /var/uits/userToRemove

touch /Library/Application\ Support/JAMF/Receipts/TempAdminInUse.dmg

# give current logged user admin rights
/usr/sbin/dseditgroup -o edit -a $U -t user admin

exit 0