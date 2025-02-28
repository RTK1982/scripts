#!/bin/bash

# Define the parameters you want to add
NEW_PARAMS="Mitigations=off noibrs noibpb no_stf_barrier tsx=on"

# Backup the current GRUB configuration
cp /etc/default/grub /etc/default/grub.bak

# Add the parameters to the GRUB_CMDLINE_LINUX_DEFAULT line in the GRUB config
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/&$NEW_PARAMS /" /etc/default/grub

# Update the GRUB configuration
update-grub

# Reboot the system to apply the changes
echo "The new boot parameters have been added. The system will now reboot."
reboot