#!/bin/sh

########## CONFIGURATION ##########
. "/cloud-storage/scripts/config"
###################################
########## DOWNLOADS ##########
# Rclone
_rclone_url="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
_rclone_zip="rclone-current-linux-amd64.zip"
_rclone_dir="rclone-v1.36-linux-amd64"

# Plexdrive
_plexdrive_url="https://github.com/dweidenfeld/plexdrive/releases/download/3.0.0/plexdrive-linux-amd64"
_plexdrive_bin="plexdrive-linux-amd64"
###################################

apt-get update
apt-get install unionfs-fuse -y
apt-get install encfs -y
apt-get install bc -y
apt-get install screen -y

if [ ! -d "${rclone_dir}" ]; then
    mkdir "${rclone_dir}"
fi
wget "${_rclone_url}"
unzip "${_rclone_zip}"
cp -r "${_rclone_dir}/*" "${rclone_dir}"
rm -rf "${_rclone_zip}"
rm -rf "${_rclone_dir}"


if [ ! -d "${plexdrive_dir}" ]; then
    mkdir "${plexdrive_dir}"
fi
wget "${_plexdrive_url}"
mv "${_plexdrive_bin}" "${plexdrive_dir}"


echo "\n\n--------- SETUP RCLONE ----------\n"

echo "1. Now run rclone with the command:"
echo "\t${rclone_bin} --config=${rclone_cfg}"
echo "2. You need to setup following:"
echo "\t- Google Drive remote"
echo "\t- Crypt for your Google Drive remote named '${rclone_cloud_endpoint%?}'"
echo "\t- Crypt for your local directory ('${cloud_encrypt_dir}') named '${rclone_local_endpoint%?}'"


echo "\n\n-------- SETUP PLEXDRIVE --------\n"

echo "1. Now run plexdrive with the command:"
echo "\t${plexdrive_bin} --config ${plexdrive_dir}"
echo "2. Cancel plexdrive by pressing CTRL+C"
echo "3. Run plexdrive with screen by running the following commands:"
echo "\tscreen -dmS plexdrive ${plexdrive_bin} --config ${plexdrive_dir}"
echo "\tscreen -RD plexdrive"