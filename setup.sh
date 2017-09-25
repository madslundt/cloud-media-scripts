#!/bin/sh

########## CONFIGURATION ##########
. "INSERT_CONFIG_FILE"
###################################
########## DOWNLOADS ##########
# Rclone
_rclone_release="rclone-v1.37-linux-amd64"
_rclone_zip="${_rclone_release}.zip"
_rclone_url="https://github.com/ncw/rclone/releases/download/v1.37/${_rclone_zip}"

# Plexdrive
_plexdrive_bin="plexdrive-linux-amd64"
_plexdrive_url="https://github.com/dweidenfeld/plexdrive/releases/download/4.0.0/${_plexdrive_bin}"
###################################

apt-get update
apt-get install unionfs-fuse -y
apt-get install bc -y
apt-get install screen -y
apt-get install unzip -y
apt-get install fuse -y
apt-get install golang -y

if [ ! -d "${rclone_dir}" ]; then
    mkdir -p "${rclone_dir}"
fi
wget "${_rclone_url}"
unzip "${_rclone_zip}"
chmod a+x "${_rclone_release}/rclone"
cp -rf "${_rclone_release}/"* "${rclone_dir}/"
rm -rf "${_rclone_zip}"
rm -rf "${_rclone_release}"


if [ ! -d "${plexdrive_dir}" ]; then
    mkdir -p "${plexdrive_dir}"
fi
wget "${_plexdrive_url}"
chmod a+x "${_plexdrive_bin}"
cp -rf "${_plexdrive_bin}" "${plexdrive_dir}/"
rm -rf "${_plexdrive_bin}"


if [ ! -d "${local_decrypt_dir}" ]; then
    mkdir -p "${local_decrypt_dir}"
fi

if [ ! -d "${plexdrive_temp_dir}" ]; then
    mkdir -p "${plexdrive_temp_dir}"
fi


echo "\n\n--------- SETUP RCLONE ----------\n"

echo "1. Now run rclone with the command:"
echo "\t${rclone_bin} --config=${rclone_config} config"

if [ "$encrypt_media" -eq "0" ]; then
    echo "2. You need to setup 1 endpoint to Google Drive remote. This is only used to upload media to your Google Drive account"
else
    echo "2. You need to setup 3 endpoints:"
    echo "\t- Google Drive remote"
    echo "\t- Crypt for your Google Drive remote named '${rclone_cloud_endpoint%?}'"
    echo "\t- Crypt for your local directory ('${cloud_encrypt_dir}') named '${rclone_local_endpoint%?}'"
fi


echo "\n\n-------- SETUP PLEXDRIVE --------\n"

mongo="--mongo-database=${mongo_database} --mongo-host=${mongo_host}"
if [ ! -z "${mongo_user}" -a "${mongo_user}" != " " ]; then
    mongo="${mongo} --mongo-user=${mongo_user} --mongo-password=${mongo_password}"
fi

echo "1. Now run plexdrive with the command:"
echo "\t${plexdrive_bin} --config=${plexdrive_dir} ${mongo} ${cloud_encrypt_dir}"
echo "2. Enter authorization"
echo "3. Cancel plexdrive by pressing CTRL+C"

echo "\n\n"

echo "Start mount by running the mount.remote [${media_dir}/scripts/mount.remote]"
echo "This can take a while because Plexdrive begins to cache your files"