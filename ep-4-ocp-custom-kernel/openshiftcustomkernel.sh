#!/bin/bash

temp_folder=/tmp
is_reboot_required=0

## Current OSTree
echo ""
echo ""
echo "###### Current OSTree ######"
rpm-ostree status

echo ""
echo "###### Target kernel details"

## Check if the conf file is present and retrieve the variables
if test -f /etc/openshiftcustomkerneld/openshiftcustomkernel.conf ; 
  then
    source /etc/openshiftcustomkerneld/openshiftcustomkernel.conf

    kernel_version=$(echo "$kernel_version" | sed 's/ *$//g')
    kernel_arch=$(echo "$kernel_arch" | sed 's/ *$//g')
    
    kernel=kernel-$kernel_version.$kernel_arch
    kernel_core=kernel-core-$kernel_version.$kernel_arch
    kernel_modules=kernel-modules-$kernel_version.$kernel_arch
    kernel_modules_extra=kernel-modules-extra-$kernel_version.$kernel_arch

    echo "target kernel_version=$kernel_version"
    echo "target kernel_arch=$kernel_arch"
    echo "target kernel package=$kernel"
    echo "target kernel_core package=$kernel_core"
    echo "target kernel_modules package=$kernel_modules"
    echo "target kernel_modules_extra package=$kernel_modules_extra"

    ## Check if the target kernel is empty

    if [ "$kernel_version" == "" ]
      then
        echo ""
        echo "###### No value set for variable kernel_version. OS will be factory reset."
        rpm-ostree reset -lo -r
        exit 0
    fi

    ## Check if the target kernel is already installed
    echo ""
    echo "###### Checking for target packages install state"
    rpm -q "$kernel_core"
    is_target_kernel_core_installed=$?
    echo ""


    ## Download and install the target kernel if not installed

    kernel_version_parts=(${kernel_version//-/ })

    if [ $is_target_kernel_core_installed -eq 0 ] ; 
      then
        echo ""
        echo "###### Target kernel already installed: $kernel_core"

      else
        rpm-ostree reset -lo

        echo ""
        echo "###### Downloading target kernel core: $kernel_core"
        echo "curl $fedora_download_base_url/${kernel_version_parts[0]}/${kernel_version_parts[1]}/$kernel_arch/$kernel_core.rpm --output $temp_folder/$kernel_core.rpm"
        curl -s "$fedora_download_base_url"/"${kernel_version_parts[0]}"/"${kernel_version_parts[1]}"/"$kernel_arch"/"$kernel_core".rpm --output $temp_folder/"$kernel_core".rpm --retry 10 --retry-all-errors
        echo ""
        echo "###### Downloading target kernel modules: $kernel_modules"
        echo "curl $fedora_download_base_url/${kernel_version_parts[0]}/${kernel_version_parts[1]}/$kernel_arch/$kernel_modules.rpm --output $temp_folder/$kernel_modules.rpm"
        curl -s "$fedora_download_base_url"/"${kernel_version_parts[0]}"/"${kernel_version_parts[1]}"/"$kernel_arch"/"$kernel_modules".rpm --output $temp_folder/"$kernel_modules".rpm --retry 10 --retry-all-errors
        echo ""
        echo "###### Downloading target kernel modules extra: $kernel_modules_extra"
        echo "curl $fedora_download_base_url/${kernel_version_parts[0]}/${kernel_version_parts[1]}/$kernel_arch/$kernel_modules_extra.rpm --output $temp_folder/$kernel_modules_extra.rpm"
        curl -s "$fedora_download_base_url"/"${kernel_version_parts[0]}"/"${kernel_version_parts[1]}"/"$kernel_arch"/"$kernel_modules_extra".rpm --output $temp_folder/"$kernel_modules_extra".rpm --retry 10 --retry-all-errors
        echo ""
        echo "###### Downloading target kernel: $kernel"
        echo "curl $fedora_download_base_url/${kernel_version_parts[0]}/${kernel_version_parts[1]}/$kernel_arch/$kernel.rpm --output $temp_folder/$kernel.rpm"
        curl -s "$fedora_download_base_url"/"${kernel_version_parts[0]}"/"${kernel_version_parts[1]}"/"$kernel_arch"/"$kernel".rpm --output $temp_folder/"$kernel".rpm --retry 10 --retry-all-errors
        
        echo ""
        echo "###### Installing the target kernel"
        rpm-ostree override replace "$temp_folder"/"$kernel_core".rpm "$temp_folder"/"$kernel_modules".rpm "$temp_folder"/"$kernel_modules_extra".rpm "$temp_folder"/"$kernel".rpm
        target_ostree_override_exit_code=$?
        
        if [[ "${target_ostree_override_exit_code}" -eq 0 ]]; then 
          is_reboot_required=1 
        fi
        ## Verify the checksum of the downloaded target kernel

        ## Check the rpm ostree 
        echo "###### Target OSTree"
        rpm-ostree status

        # echo "## Clean up"
        echo ""
        echo "###### Clean up downloaded files"
        ls -lrt /tmp && rm -rf  /tmp/kernel* && ls -lrt /tmp

        ## Reboot to make the new rpm ostree effective
        echo ""
        echo "###### Is reboot required?: $is_reboot_required"
        if [[ "${is_reboot_required}" -eq 1 ]]; then
          systemctl reboot
        fi

    fi
  else  
    echo ""
    echo "###### Could not process the /etc/openshiftcustomkerneld/openshiftcustomkernel.conf file"
fi