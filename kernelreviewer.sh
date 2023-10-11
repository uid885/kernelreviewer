#!/bin/bash -
# Author        : Christo Deale
# Date	        : 2023-10-11
# kernelreviewer: Utility to Review current Kernels with options to make default Kernel or delete old Kernel

# Function to print a message in red color
print_red() {
  echo -e "\e[91m$1\e[0m"
}

# Function to remove a kernel and related packages
remove_kernel() {
  local kernel_version="$1"
  # Add a wildcard character (*) to match any kernel version starting with the specified string
  sudo yum remove "kernel-${kernel_version}*"
  echo "Kernel $kernel_version and related packages have been removed."
  echo "Remember to reboot the system to apply the changes."
}

# Function to set a new default kernel
set_default_kernel() {
  local kernel_version="$1"
  sudo grub2-set-default "kernel-$kernel_version"
  echo "Default kernel has been set to $kernel_version."
  echo "Updating GRUB configuration..."
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  echo "GRUB configuration has been updated."
  echo "Remember to reboot the system to boot with the new default kernel."
}

# Get the current kernel version
current_kernel=$(uname -r)

# List all installed kernels and format them with an asterisk (*) for the current kernel
kernel_list=$(rpm -q kernel | sed "s/^kernel-\(.*\)/\1/" | awk -v current="$current_kernel" '{if ($0 == current) {print "*"$0} else {print " "$0}}')

# Print the list of installed kernels with the current kernel marked with an asterisk in red
print_red "List of installed kernels:"
while IFS= read -r kernel_line; do
  if [[ "$kernel_line" == *"*"* ]]; then
    print_red "$kernel_line"
  else
    echo "$kernel_line"
  fi
done <<< "$kernel_list"

# Ask the user for their choice
echo -e "\nOption A: Enter the full Kernel version to delete (e.g., 5.14.0-284.18.1.el9_2.x86_64)"
echo "Option B: Enter the full Kernel version to make default (e.g., 5.14.0-284.18.1.el9_2.x86_64), or 'q' to quit:"
read -p "Your choice: " choice

if [[ "$choice" == "q" ]]; then
  echo "Exiting the script."
elif [[ "$choice" == [Aa] ]]; then
  read -p "Enter the full kernel version to delete: " kernel_to_delete
  matching_kernel=$(echo "$kernel_list" | grep -i " $kernel_to_delete")
  if [[ -n "$matching_kernel" ]]; then
    # Remove the leading space and formatting to get the actual kernel version for removal
    kernel_version=$(echo "$matching_kernel" | sed 's/^ *//')
    remove_kernel "$kernel_version"
  else
    echo "No matching kernel found. Please enter a valid kernel version from the list."
  fi
elif [[ "$choice" == [Bb] ]]; then
  read -p "Enter the full kernel version to set as the new default kernel: " kernel_to_set_default
  matching_kernel=$(echo "$kernel_list" | grep -i " $kernel_to_set_default")
  if [[ -n "$matching_kernel" ]]; then
    # Remove the leading space and formatting to get the actual kernel version for setting as the default
    kernel_version=$(echo "$matching_kernel" | sed 's/^ *//')
    set_default_kernel "$kernel_version"
  else
    echo "No matching kernel found. Please enter a valid kernel version from the list."
  fi
else
  echo "Invalid choice. Exiting the script."
fi
