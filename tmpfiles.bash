#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=`dirname $SCRIPT`

function get_variable {
    ARG=$1
    eval "json_var_$ARG=$(echo $RESPONSE | $SCRIPT_DIR/jq '.response|.[]|.'$ARG | sed -e 's/^"//' -e 's/"$//')"
}

function run_help {

    printf "Uploads a file to tmpfiles.com\n"
    printf "\t-f | --file\t\t\t[REQUIRED] Path to file\n"
    printf "\t-x | --expire\t\t\t[OPTIONAL] [INT] Number of hours to expire the file, default 24\n"
    printf "\t-d | --download-count\t\t[OPTIONAL] [INT] Number of downloads to allow, default 1\n"
    printf "\t-p | --password\t\t\t[OPTIONAL] Will require a password to download.\n\t\t\t\t\t\t\tFile will be encrypted tmpfiles.com server with this password.\n\t\t\t\t\t\t\tYou can either put the password in the argument, or it will prompt you if not\n"
    printf "\t-h | --help\t\t\t Show this help menu and quit\n"
}

EXPIRE=""
DL_COUNT=1
HAS_PASSWORD=false
PASSWORD=""
while :
do
    case "$1" in
      -f | --file)
	  FILE="$2"
	  if [ ! -f $FILE ];then
             echo "Unable to locate $FILE" >&2;exit 1
	  fi
	  FILE_NAME=$(basename $FILE)
	  shift 2
	  ;;
      -x | --expire)
          if ! [[ $2 =~ ^[0-9]+$ ]]; then
              echo "Expiration must be an integer (in hours)" >&2; exit 1
          fi
	  EXPIRE=$(date --date="+$2 hour" +"%Y-%m-%dT%T")
	  shift 2
	  ;;
      -d | --download-count)
          if ! [[ $2 =~ ^[0-9]+$ ]]; then
              echo "Download count be an integer" >&2; exit 1
          fi
          DL_COUNT="$2"
          shift 2
          ;;

      -p | --password)
          HAS_PW=true
          if [ "$2" = '' ] || [[ "$2" =~ ^- ]];then
              shift
          else
              PW=$2
	      shift 2 
          fi
          ;;
      -h | --help)
	  run_help; exit 0	  
          ;;
      --) # End of all options
	  shift
	  break
	  ;;
      -*)
	  echo "Error: Unknown option: $1" >&2
	  run_help; exit 1
	  ;;
      *)  # No more options
	  break
	  ;;
    esac
done
# we got a file?
if [ -z "$FILE" ];then
    echo "You must set a file with '-f'" >&2; exit 1
fi

# check if we have a password, and if we want one
if [ "$HAS_PW" = true ] && [ "$PW" = '' ];then
    read -s -p "Enter Password: " PASSWORD
else
    PASSWORD=$PW
fi

if [ "$HAS_PW" = true ] && (( ${#PASSWORD} < 4 ));then
    echo "Password must be at least 3 characters" >&2; exit 1
fi


echo "Starting upload..."
RESPONSE=$(curl -s -X POST -H "Content-Type: multipart/form-data" \
    -F "name=$FILE_NAME" \
    -F "expire_timestamp=$EXPIRE" \
    -F "expire_views=$DL_COUNT" \
    -F "password=$PASSWORD" \
    -F "filesToUpload=@$FILE" \
    https://tmpfiles.com/file/upload/)

get_variable success

if [ "$json_var_success" != 'true' ];then
    ERROR=$(echo $RESPONSE | jq '.error')
    echo "An error occured processing your file: $ERROR" >&2; exit 1
fi

# Check out file hashes
FILE_HASH=($(md5sum $FILE))
get_variable hash
HASH_MATCH=false
if [ "$FILE_HASH" != $json_var_hash ]; then
    echo -e "\e[41m\e[30mFILE HASHS DO NOT MATCH!\e[0m"
    echo "Ours: $FILE_HASH";
    echo "Theirs: $json_var_hash"
else
    echo -e "\e[42m\e[30mFile was Successfully uploaded.\e[0m"
    HASH_MATCH=true
fi

get_variable name
echo -e "File Name: \e[32m$json_var_name\e[0m"

get_variable browse_link
echo -e "File URL: \e[32m$json_var_browse_link\e[0m"

if [ "$HASH_MATCH" = true ];then
    echo -e "Hashs Match: \e[36m$json_var_hash\e[0m" 
fi

get_variable expire_timestamp

HUMAN_DATE=$(date -d @$json_var_expire_timestamp)
echo -e "File Expires at \e[31m$HUMAN_DATE\e[0m"

exit 0;
