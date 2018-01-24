These scripts are created to have your media synced between your cloud- and local store. All media is always encrypted before being uploaded.
This also means if you loose your encryption keys you can't read your media.

**Plexdrive version 4.0.0 and Rclone version 1.39 is used.**

The config right now is configured to have atleast 1 TB for caching and a decent internet connection. If you have a smaller drive or just want to optimize it [click here](#optimize-configuration-wip).

### I've created another repository with this included in a docker image. Check it out [here](https://github.com/madslundt/docker-cloud-media-scripts)

# Easy install
git, curl and bash is needed to run easy install.
```
sudo apt-get install git-core curl bash -y
```

Now run:
```
bash <( curl -Ls https://github.com/madslundt/cloud-media-scripts/raw/master/INSTALL )
```

By default this will place cloud-media-scripts in the directory `./cloud-media-scripts`. An extra argument can be added to change this

```
bash <( curl -Ls https://github.com/madslundt/cloud-media-scripts/raw/master/INSTALL ) [PATH]
```

This has only been tested on Ubuntu 16.04+. Please create an issue if you have any problems.

# Content
* [How this works?](#how-this-works)
  * [Plexdrive](#plexdrive)
  * [Rclone](#rclone)
  * [UnionFS](#unionfs)
* [Installation without easy install](#installation-without-easy-install)
  * [Setup](#setup)
  * [Setup cronjobs](#setup-cronjobs)
* [My setup](#my-setup)
* [Optimize configuration WIP](#optimize-configuration-wip)
* [Upgrade](#upgrade)
* [Donate](#donate)

# How this works?
Following services are used to sync, encrypt/decrypt and mount media:
 - Plexdrive
 - Rclone
 - UnionFS

This gives us a total of 5 directories:
 - Cloud encrypt dir: Containing encrypted data from the cloud provider (Mounted with Plexdrive)
 - Cloud decrypt dir: Containing decrypted data by decrypting the cloud encrypt dir (Mounted with Rclone). If encryption is turned off this will be mounted directly with Plexdrive.
 - Local decrypt dir: Containing local data stored locally on the hard drive.
 - Plexdrive temp dir: Containing temp/cache data from Plexdrive. This prevents Plexdrive from redownloading files everytime they are accessed.
 - Local media dir: Containing all data from cloud provider and data stored locally (Mounted with Union-FS).

Cloud data are mounted to a local folder (`cloud_encrypt_dir`). This folder is then decrypted and mounted to a local folder (`cloud_decrypt_dir`).

A local folder (`local_decrypt_dir`) is created to contain media stored locally.
The local folder (`local_decrypt_dir`) and cloud folder (`cloud_decrypt_dir`) is then mounted to a third folder (`local_media_dir`) with certain permissions - local folder with Read/Write permissions and cloud folder with Read-only permissions.

Everytime new media is retrieved it should be added to `local_media_dir` or `local_decrypt_dir`. By adding new data to `local_media_dir` it will automatically write it down to `local_decrypt_dir` because of the write permissions.

Sooner or later media is going to be removed from `local_decrypt_dir` depending on the `remove_files_based_on` setting. Media is only removed from `local_decrypt_dir` and still appears in `local_media_dir` because it is still accessable from the cloud.

If `remove_files_based_on` is set to **space** it will only move data to the cloud (if local media size has exceeded `remove_files_when_space_exceeds` GB) starting from the oldest accessed file and will only free up atleast `freeup_atleast` GB. If **time** is set it will only move files older than `remove_files_older_than` to the cloud. If **instant** is set it will make sure to move all media to the cloud for then afterwards removing it locally.

*Media is always uploaded to cloud before removing it locally.*

![UML diagram](uml_diagram.png)

## Plexdrive
Plexdrive is used to mount Google Drive to a local folder (`cloud_encrypt_dir`).

Plexdrive version 4.0.0 requires a running MongoDB server. This is not included in the scripts but can either be installed from .deb packages or in a Docker container.

Plexdrive create two files: `config.json` and `token.json`. This is used to get access to Google Drive. These can either be set up via Plexdrive or by using the templates located in the [plexdrive directory](plexdrive/) (copy the files, name them `config.json` and `token.json` and insert your Google API details).

## Rclone
Rclone is used to encrypt, decrypt and upload files to the cloud.
Rclone is used to mount and decrypt Plexdrive to a different folder (`cloud_decrypt_dir`).
Rclone encrypts and uploads from a local folder (`local_decrypt_dir`) to the cloud.

Rclone creates a config file: `config.json`. This is used to get access to the cloud provider and encryption/decryption keys. This can either be set up via Rclone or by using the templates located in the [rclone directory](rclone/) (just copy the file and name it `rclone.conf`).

Some have reported permission issues with Rclone directory. If that occurs it can be fixed by setting `--uid` in `rclone_mount_options` in [config.json](config.json).

## UnionFS
UnionFS is used to mount both cloud and local media to a local folder (`local_media_dir`).

 - Cloud media is mounted with Read-only permissions.
 - Local media is mounted with Read/Write permissions.

The reason for these permissions are that when writing to the local folder (`local_media_dir`) it will not try to write it directly to the cloud folder, but instead to the local media (`local_decrypt_dir`). Later this will be encrypted and uploaded to the cloud by Rclone.

## Setup
# Installation without easy install
1. Change `config` to match your settings.
2. Change paths to config in all script files.
3. Run `bash setup.sh` and follow the instructions*.
4. Run `./mount.remote` to mount plexdrive and decrypt by using rclone.

To unmount run `./umount.remote`

*If this doesn't work, follow the manual setup instructions [here](#manually).

### Rclone setup
Most of the configuration to set up is done through Rclone. Read their documentation [here](https://rclone.org/docs/).

3 remotes are needed:
 - Endpoint to your cloud storage.
	- Create new remote [**Press N**]
	- Give it a name (*default in config gd*)
	- Choose Google Drive [**Press 8**]
	- If you have a client id paste it here or leave it blank
	- Choose headless machine [**Press N**]
	- Open the url in your browser and enter the verification code
 - Encryption and decryption for your cloud storage.
	- Create new remote [**Press N**]
	- Give it the same name as the variable `rclone_cloud_endpoint` specified in the config but without colon (:) (*default in config gd-crypt*)
	- Choose Encrypt/Decrypt a remote [**Press 5**]
	- Enter the name of the endpoint created in cloud-storage appended with a colon (:) and the subfolder on your cloud. Example `gd:/Media` or just `gd:` if you have your files in root in the cloud.
	- Choose how to encrypt filenames. I prefer option 2 Encrypt the filenames
	- Choose to either generate your own or random password. I prefer to enter my own.
	- Choose to enter pass phrase for the salt or leave it blank. I prefer to enter my own.
 - Encryption and decryption for your local storage.
	- Create new remote [**Press N**]
	- Give it the same name as specified in the environment variable `rclone_local_endpoint` but without colon (:) (*default in config local-crypt*)
	- Choose Encrypt/Decrypt a remote [**Press 5**]
	- Enter the encrypted folder specified as `cloud_encrypt_dir` in config. If you are using subdirectory on Google Drive append it to it. Example /.cloud-encrypt/Media
	- Choose the same filename encrypted as you did with the cloud storage.
	- Enter the same password as you did with the cloud storage.
	- Enter the same pass phrase as you did with the cloud storage.

Rclone documentation if needed [click here](https://rclone.org/docs/)

View my example for an rclone configuration [here](rclone/rclone.template.conf).

_Good idea to backup your Rclone configuration and Plexdrive configuration and cache for easier setup next time._

### Manually
To install the necessary stuff manually do the following:
1. Install unionfs-fuse.
2. Install bc.
3. Install GNU screen.
4. Install [Rclone 1.39](https://github.com/ncw/rclone/releases/download/v1.39/rclone-v1.39-linux-amd64).
5. Install [Plexdrive 4.0.0](https://github.com/dweidenfeld/plexdrive/releases/download/4.0.0/plexdrive-linux-amd64).
6. Create the folders pointing, in the config file, to `local_decrypt_dir` and `plexdrive_temp_dir`.
7. Run rclone bin, installed in step 4, with the parameter `--config=RCLONE_CONFIG config` where `RCLONE_CONFIG` is the variable set in the config file.
8. Set up Google Drive remote, Crypt for Google Drive remove (rclone_cloud_endpoint) and crypt for local directory (rclone_local_endpoint).
9. Run plexdrive bin, installed in step 5, with the parameters `--config=PLEXDRIVE_DIR --mongo-database=MONGO_DATABASE --mongo-host=MONGO_HOST --mongo-user=MONGO_USER --mongo-password=MONGO_PASSWORD`. Remember to match the parameters with the variables in the config file.
10. Enter authorization to your Google Drive.
11. Cancel Plexdrive by pressing CTRL+C.
Run PlexDrive with GNU screen: `screen -dmS plexdrive PLEXDRIVE_BIN --config=PLEXDRIVE_DIR --mongo-database=MONGO_DATABASE --mongo-host=MONGO_HOST --mongo-user=MONGO_USER --mongo-password=MONGO_PASSWORD PLEXDRIVE_OPTIONS CLOUD_ENCRYPT_DIR`.
12. Exit screen session by pressing CTRL+A then D.

## Setup cronjobs
My suggestions for cronjobs is in the file `cron`.
These should be inserted into `crontab -e`.
I suggest to wait a minute to start Plex to make sure the mount is up and running.

 - Mount 20 seconds after boot.
 - Checks if mount is up 40 seconds after boot (if not it makes sure to remount).
 - Upload to cloud daily at 03:30 AM.
 - Check to remove local content every tuesday after upload has finished (this only remove files depending on the option 'space', 'time' or 'instant').
 - Check hourly that mount is up or else remounting.
 - Check every 12th hour if mount is up and running (if not it makes sure to remount). If mount is up and running, it will empty Plex trash.

_If you have a small local disk you may change upload and remove local content to do it more often._

*_If 'space' is set it will only move content to cloud, starting from the oldest accessed file, if media size has exceeded `remove_files_when_space_exceeds`, and will free up atleast `freeup_atleast`. If 'time' is set it will only move files to cloud older than `remove_files_older_than`. If 'instant' is set it will move all files to cloud when running. Only when file has been successfully moved to cloud it will be deleted locally._

*Media is never deleted locally before being uploaded successfully to the cloud.*

OBS: `mountcheck` is used to check if mount is up. I've had some problems where either Plexdrive or Rclone stops the mount. `mountcheck` will make sure to mount your stuff again if something like this happens.


# My setup
My setup with this is quite simple.

I've an Intel NUC with only 128GB ssd. This is connected to a 4TB external hard drive that contains local media recently downloaded (`local_decrypt_dir`) and recently streamed media (plexdrive cache `plexdrive_temp_dir`).

I'm running this with up to 1TB plexdrive cache (`--clear-chunk-max-size=1000G`) and removing files based on space (`remove_files_based_on="space"`) when `local-decrypt-dir` exceeds 2TB (`remove_files_when_space_exceeds=2000`) and frees up atleast 1TB (`freeup_atleast=1000`). 

# Optimize configuration WIP
## Space
Right now the config is set for atleast 1 TB drive.

To use these scripts on a smaller drive, make these changes to the config:

Plexdrive
 - `clear-chunk-max-size` the allowed space for plexdrive cache. After the space of this has exceeded, the older blocks will be overwritten.
 - `clear-chunk-age` the expiration of plexdrive cache. After expiration the blocks will be deleted (this is only used when clear-chunk-max-size is removed).

Misc. config
 - remove_files_based_on can either be time, space or instant.
    - Time will move the files to the cloud after `remove_files_older_than` days and afterwards remove them locally.
    - Space will move the files to the cloud, starting from the oldest, when space exceeds `remove_files_when_space_exceeds` and free up atleast `freeup_atleast` GB. Afterwards these files are removed locally.
    - Instant will move all the files to the cloud and afterwards remove them locally.

## Internet connection
Depending on your internet connection, you can optimize when plexdrive download chunks.

Plexdrive
 - `chunk-size` the size of the chunks downloaded by Plexdrive. For faster connections increase this.

# Upgrade
You can easily upgrade those scripts with the following command
```
git pull origin master
```

# Donate
If you want to support the project or just buy me a beer I accept Paypal and bitcoins.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/madslundt)

BitCoin address: 18fXu7Ty9RB4prZCpD8CDD1AyhHaRS1ef3

![bitcoin](https://i.imgur.com/vlzF8Ep.png)
