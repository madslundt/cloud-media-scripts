#!/bin/sh

########## CONFIGURATION ##########
. "/cloud-storage/scripts/config"
###################################

apt-get update
apt-get install unionfs-fuse -y
apt-get install encfs -y
apt-get install bc -y
apt-get install screen -y

if [ ! -d "${rclone_dir}" ]; then
    mkdir "${rclone_dir}"
fi
wget https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip
cp -r rclone-v1.36-linux-amd64/* "${rclone_dir}"
rm -rf rclone-current-linux-amd64.zip
rm -rf rclone-v1.36-linux-amd64

# Remember to check https://github.com/dweidenfeld/plexdrive/releases for newer versions
if [ ! -d "${plexdrive_dir}" ]; then
    mkdir "${plexdrive_dir}"
fi
wget https://github.com/dweidenfeld/plexdrive/releases/download/3.0.0/plexdrive-linux-amd64
mv plexdrive-linux-amd64 "${plexdrive_dir}"

echo "\n\n\nRemember to check https://github.com/dweidenfeld/plexdrive/releases for newer versions"
echo "And https://downloads.rclone.org/"

echo "\n\n---------SETUP RCLONE----------\n"

# RUN THIS AFTER
echo "1. Now run rclone with the command:"
echo "\t ./${rclone_bin} --config=${rclone_cfg}"
echo "2. You need to setup following:"
echo "   - Google Drive remote named '${rclone_cloud_endpoint}'"
echo "   - Crypt for your remote '${rclone_cloud_endpoint}' named '${rclone_local_endpoint}'"
echo "   - Crypt for your local directory named '${cloud_encrypt_dir}'"

echo "\n\n--------SETUP PLEXDRIVE--------\n"

echo "1. Now run plexdrive with the command:"
echo "\t ./${plexdrive_bin} --config ${plexdrive_dir}"
echo "2. Cancel plexdrive by pressing CTRL+C"
echo "3. Run plexdrive with screen by running the following commands:"
echo "\tscreen -dmS plexdrive ${plexdrive_bin} --config ${plexdrive_dir}'"
echo "\tscreen -RD plexdrive"

echo "\n\n\nRemember to check https://github.com/dweidenfeld/plexdrive/releases for newer versions"
echo "And https://downloads.rclone.org/"