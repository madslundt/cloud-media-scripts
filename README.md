# Getting started
1. Change config to match your settings.
2. Change configuration in each file to point to config.
3. Run `sudo sh setup.sh` and follow the instructions.
4. Run `./mount.remote all` to mount plexdrive and decrypt by using rclone.

To unmount run `./umount.remote all`

At the moment `makecache` has not been tested and `scanlibraries` is not probably configured.

### Cron
Copy `cron` and paste into `crontab -e`.

 - Cron is set up to mount at boot.
 - Uploaded to cloud hourly.
 - Create cache daily.
 - Check to remove local content daily (this only remove files older than remove_files_older_than).

Original scripts from `git://git.gesis.pw:/nimbostratus.git`