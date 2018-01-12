#!/bin/bash

########## CONFIGURATION ##########
. "INSERT_CONFIG_FILE"
###################################
########## DOWNLOADS ##########
# Rclone
_rclone_version="v1.39"
_rclone_release="rclone-${_rclone_version}-linux-amd64"
_rclone_zip="${_rclone_release}.zip"
_rclone_url="https://github.com/ncw/rclone/releases/download/${_rclone_version}/${_rclone_zip}"

# Plexdrive
_plexdrive_bin="plexdrive-linux-amd64"
_plexdrive_url="https://github.com/dweidenfeld/plexdrive/releases/download/4.0.0/${_plexdrive_bin}"
###################################

sudo apt-get update

echo "Installing dependencies"
sudo apt-get -qq install unionfs-fuse -y
sudo apt-get -qq install bc -y
sudo apt-get -qq install screen -y
sudo apt-get -qq install unzip -y
sudo apt-get -qq install fuse -y
sudo apt-get -qq install golang -y
sudo apt-get -qq install libxml-xpath-perl -y

printf "\n\nChecking Rclone and Plexdrive"

onlyUpdate=0
if [ -f "${rclone_bin}" ]; then
    if ${rclone_bin} --config=${rclone_config} --version | grep -q "${_rclone_version}"; then
        rerunSetup=""
        while [ "${rerunSetup,,}" != "n"  ] && [ "${rerunSetup,,}" != "y"  ]
        do
            read -e -p "Rclone is already in version ${_rclone_version}. Do you want to run setup anyway? [Y/n]? " -i "y" rerunSetup
        done
        
        if [ "${rerunSetup,,}" == "n"  ]; then
            echo "Exiting setup"
            exit 0
        fi
    fi
    onlyUpdate=1
fi

if [ ! -d "${rclone_dir}" ]; then
    mkdir -p "${rclone_dir}"
fi
wget "${_rclone_url}"
mkdir "${media_dir}/${_rclone_release}"
unzip "${_rclone_zip}" -d "${media_dir}"
cp -rf "${media_dir}/${_rclone_release}/"* "${rclone_dir}/"
chmod a+x "${rclone_bin}"
rm -rf "${_rclone_zip}"
rm -rf "${media_dir}/${_rclone_release}"

if [ ! -d "${plexdrive_dir}" ]; then
    mkdir -p "${plexdrive_dir}"
fi
wget "${_plexdrive_url}"
cp -rf "${_plexdrive_bin}" "${plexdrive_dir}"
chmod a+x "${plexdrive_bin}"
rm -rf "${_plexdrive_bin}"

sudo sed -i "s|#user_allow_other|user_allow_other|g" "/etc/fuse.conf"
chmod a+x "${media_dir}/scripts/"*

if [ ! -d "${local_decrypt_dir}" ]; then
    mkdir -p "${local_decrypt_dir}"
fi

if [ ! -d "${plexdrive_temp_dir}" ]; then
    mkdir -p "${plexdrive_temp_dir}"
fi

if [ -f $rclone_config ]; then
    echo "Rclone config already exists"
    rcloneInstallText="Do you want to change Rclone config now"
else
    echo "No Rclone config exists"
    rcloneInstallText="Do you want to set up Rclone now"
fi

rcloneSetup=""
answer="y"
if [ "${onlyUpdate}" == "1" ]; then
    answer="n"
fi
while [ "${rcloneSetup,,}" != "n"  ] && [ "${rcloneSetup,,}" != "y"  ]
do
    read -e -p "${rcloneInstallText} [Y/n]? " -i answer rcloneSetup
done


if [ "${rcloneSetup,,}" == "y"  ]; then
    printf "=======RCLONE========\n\n"
    if [ ! -f $rclone_config ]; then
        cp "${rclone_dir}/rclone.template.conf" "${rclone_config}"
        printf "\t+ Google Drive credentials are needed within Rclone. This must be added to the Rclone remote 'gd'\n"
        if [ "$encrypt_media" != "0" ]; then
            sed -i "s|<GOOGLE_DRIVE_MEDIA_DIRECTORY>|${google_drive_media_directory}|g" "${rclone_config}"
            sed -i "s|\[gd-crypt\]|\[${rclone_cloud_endpoint%?}\]|g" "${rclone_config}"
            sed -i "s|<ENCRYPTED_FOLDER>|${cloud_encrypt_dir}|g" "${rclone_config}"
            printf "\t+ Password and a salt are needed within Rclone when using encryption. This must be added to the Rclone remote '${rclone_cloud_endpoint%?}' and '${rclone_local_endpoint%?}'\n"
        fi
    fi
    printf "\nWhen this is done exit rclone config by pressing 'Q'\n"
    ${rclone_bin} --config=${rclone_config} config
    printf "\nRclone has successfully been updated\n"
fi

if [ ! -f "${plexdrive_dir}/token.json" ]; then
    plexdriveSetup=""
    while [ "${plexdriveSetup,,}" != "n"  ] && [ "${plexdriveSetup,,}" != "y"  ]
    do
        read -e -p "Do you want to set up Plexdrive now [Y/n]? " -i "y" plexdriveSetup
    done

    if [ "${plexdriveSetup,,}" == "y"  ]; then
        printf "======PLEXDRIVE======\n\n"
        mongo="--mongo-database=${mongo_database} --mongo-host=${mongo_host}"
        if [ ! -z "${mongo_user}" -a "${mongo_user}" != " " ]; then
            mongo="${mongo} --mongo-user=${mongo_user} --mongo-password=${mongo_password}"
        fi
        echo "After credentials have been added exit Plexdrive by pressing CTRL+C"
        ${plexdrive_bin} --config=${plexdrive_dir} ${mongo} ${cloud_encrypt_dir}
        echo "Plexdrive has successfully been updated"
    fi
else
    echo "Plexdrive config already exists."
fi

printf "\n\n"
mountStart=""
while [ "${mountStart,,}" != "n"  ] && [ "${mountStart,,}" != "y"  ]
do
    if [ "${onlyUpdate}" == "1" ]; then
        read -e -p "Do you want to remount now [Y/n]? " -i "y" mountStart
    else
        read -e -p "Do you want to start mounting now [Y/n]? " -i "y" mountStart
    fi
done

if [ "${mountStart,,}" == "y"  ]; then
    if [ "${onlyUpdate}" == "1" ]; then
        bash ${media_dir}/scripts/umount.remote
    else
        printf "\nThis may take a while because Plexdrive needs to cache your files\n"
    fi
    bash ${media_dir}/scripts/mount.remote
else
    printf "\nStart mount later by running the mount.remote [${media_dir}/scripts/mount.remote]\n"
    echo "Or running setup again"
fi
