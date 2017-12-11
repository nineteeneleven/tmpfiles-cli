# Uploads a file to [tmpfiles.com](https://tmpfiles.com)
To install so you can access from anywhere you can symlink tmpfiles.bash to /bin. `ln -s /path/to/tmpfiles.bash /bin/tmpfiles`
Then you will be able to just run `tmpfiles -f /path/to/somefile.txt` anywhere
# Arguments
 * `-f` | `--file` [REQUIRED] Path to file
 * `-x` | `--expire` [OPTIONAL] [INT] Number of hours to expire the file, default 24
 * `-d` | `--download-count` [OPTIONAL] [INT] Number of downloads to allow, default 1
 * `-p` | `--password` [OPTIONAL] Will require a password to download. File will be encrypted tmpfiles.com server with this password. You can either put the password in the argument, or it will prompt you if not
 * -h | --help                      Show this help menu and quit


### Written by John Brechisci


jq is provided by https://github.com/stedolan/jq, their license can be [found here](https://github.com/stedolan/jq/blob/master/COPYING)
