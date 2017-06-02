These scripts are created to have your media synced between your cloud- and local store. Everytime media is uploaded to the cloud it is always encrypted before hitting the cloud.
This also means if you loose your encryption keys you can't read your media.

# Getting started
1. Change `config` to match your settings.
2. Change configuration in each file to point to config.
3. Run `sudo sh setup.sh` and follow the instructions.
4. Run `./mount.remote all` to mount plexdrive and decrypt by using rclone.

To unmount run `./umount.remote all`

# Cron
My suggestions for cronjobs is in the file `cron`.
These should be inserted into `crontab -e`.

 - Cron is set up to mount at boot.
 - Uploaded to cloud hourly.
 - Create cache daily (ignore this for now).
 - Check to remove local content daily (this only remove files older than `remove_files_older_than`).

## OBS
At the moment `makecache` has not been tested and `scanlibraries` is not probable configured.
_These might be removed in the future if Plex works fine without them and without increasing API hits drastically._

# How does it work?
Following services are used to sync, encrypt/decrypt and mount media:
 - Plexdrive
 - Rclone
 - UnionFS

Cloud is mounted to a local folder (`cloud_encrypt_dir`). This folder is then decrypted and mounted to a local folder (`cloud_decrypt_dir`).

A local folder (`local_decrypt_dir`) is created to contain local media.
The local folder (`local_decrypt_dir`) and cloud folder (`cloud_decrypt_dir`) is then mounted to a third folder (`local_media_dir`) with certain permissions - local folder with Read/Write permissions and cloud folder with Read-only permissions.

Everytime new media wants to be added it should be added to the `local_media_dir` or directly to the `local_decrypt_dir`.
Keep in mind that if it is written and read from `local_decrypt_dir` it will sooner or later be removed from this folder depending on the `remove_files_older_than` setting. This is only removed from `local_decrypt_dir` and would still appear in `local_media_dir` because it would still be accessable in the cloud.

## Plexdrive
Plexdrive is used to mount Google Drive to a local folder (`cloud_encrypt_dir`).

## Rclone
Rclone is used to encrypt, decrypt and upload files to the cloud.
Rclone is used to mount and decrypt Plexdrive to a different folder (`cloud_decrypt_dir`).
Rclone encrypts and uploads from a local folder (`local_decrypt_dir`) to the cloud.

## UnionFS
UnionFS is used to mount both cloud and local media to a local folder (`local_media_dir`).
Cloud media is mounted with Read-only permissions.
Local media is mounted with Read/Write permissions.

The reason for these permissions are that if you write to the local folder (`local_media_dir`) it will write it will not try to write it directly to your cloud folder, but instead to your local media (`local_decrypt_dir`). Later this will be encrypted and uploaded to the cloud by Rclone.

# Thanks to
Gesis for the original scripts: `git://git.gesis.pw:/nimbostratus.git`