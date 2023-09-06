#!/bin/bash
API_KEY=${ENV_GODADDY_API_KEY}
API_SECRET=${ENV_GODADDY_API_SECRET}
DOMAIN="${ENV_DNS_DOMAIN}"
ENABLE_DNS_MANAGEMENT=false
PORT=10901
TTL=600
PROTOCOL="_tcp"
SERVICE="_thanosquery"
COMMAND="add"
PRIORITY=0
WEIGHT=0
SUBDOMAIN="prometheus.monitoring"

LOGLEVEL="info"

#create function for logging depending on LOGLEVEL
_log() {
  messagelevel=$1
  # $1 - loglevel internal
  # $2 - message
  if [[ $LOGLEVEL == "debug" ]]; then
    echo -e "${messagelevel^^}: $2"
  ##  if LOGLEVEL is info and messagelevel in list of allowed values: info|warning|critical
  elif [[ $LOGLEVEL == "info" ]] && [[ $messagelevel =~ ^(info|warning|critical)$ ]]; then
    echo -e "${messagelevel^^}: $2"
  elif [[ $LOGLEVEL == "warning" ]] && [[ $messagelevel =~ ^(warning|critical)$ ]]; then
    echo -e "${messagelevel^^}: $2"    
  elif [[ $LOGLEVEL == "critical" ]] && [[ $messagelevel =~ ^(critical)$ ]]; then
    echo -e "${messagelevel^^}: $2"    
  fi
}

## parse arguments
# Loop through the arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--enable)
      ENABLE_DNS_MANAGEMENT=true
      shift
      ;;
    -s|--stand)
      if [ -n "$2" ]; then
        ## set STAND="$2" remove quotes
        STAND=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if STAND is a string beginnig with letter 
        if [[ ! $STAND =~ ^[a-zA-Z-][a-zA-Z0-9-]+$ ]]; then
          echo "--stand should be a string. Exit"
          exit 1
        fi
        shift
      else
        _log "critical" "Error: --stand requires a value (string)."
        exit 1
      fi
      shift
      ;;
    --protocol)
      if [ -n "$2" ]; then
        PROTOCOL=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        shift
      else
        PROTOCOL="_tcp"
      fi
      shift
      ;;

    -p|--port)
      if [ -n "$2" ]; then
        PORT=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if PORT is a number or not  `exit 1`
        if [[ ! $PORT =~ ^[0-9]+$ ]]; then
          _log "critical" "--port is not a number. Exit"
          exit 1
        fi
        shift
      else
        PORT=10901
      fi
      shift
      ;;

    --ttl)
      if [ -n "$2" ]; then
        TTL=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if TTL is a number or not  `exit 1`
        if [[ ! $TTL =~ ^[0-9]+$ ]]; then
          _log "critical" "--ttl is not a number. Exit"
          exit 1
        fi
        shift
      else
        TTL=600
      fi
      shift
      ;;

    --priority)
      if [ -n "$2" ]; then
        PRIORITY=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if PRIORITY is a number or not  `exit 1`
        if [[ ! $PRIORITY =~ ^[0-9]+$ ]]; then
          _log "critical" "--priority is not a number. Exit"
          exit 1
        fi
        shift
      else
        PRIORITY=0
      fi
      shift
      ;;

    --weight)
      if [ -n "$2" ]; then
        WEIGHT=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if WEIGHT is a number or not  `exit 1`
        if [[ ! $WEIGHT =~ ^[0-9]+$ ]]; then
          _log "critical" "--weight is not a number. Exit"
          exit 1
        fi
        shift
      else
        WEIGHT=0
      fi
      shift
      ;;

    --service)
      if [ -n "$2" ]; then
        SERVICE=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if SERVICE is a string or not  `exit 1` SERVICE should start with _ and contain only letters
        if [[ ! $SERVICE =~ ^_[a-zA-Z]+$ ]]; then
          _log "critical" "--service should start with _ and contain only letters. Exit"
          exit 1
        fi   
        shift
      else
        SERVICE="_thanosquery"
      fi
      shift
      ;;

    -r|--record_name)
      if [ -n "$2" ]; then
        RECORD_NAME=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if RECORD_NAME is a string or not  `exit 1`  
        if [[ ! $RECORD_NAME =~ ^[a-zA-Z][a-zA-Z0-9-]+$ ]]; then
          _log "critical" "--record_name should be a string. Exit"
          exit 1
        fi
        shift
      else
        _log "critical" "Error: --record_name requires a value (string)."
        exit 1
      fi
      shift
      ;;


    -d|--domain)
      if [ -n "$2" ]; then
        DOMAIN=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if DOMAIN is a domain or not  `exit 1` 
        if [[ ! $DOMAIN =~ ^[a-zA-Z]+.+[a-zA-Z]+$ ]]; then
          _log "critical" "--domain should be a domain. Exit"
          exit 1
        fi  
        shift
      else
        # use ENV variable ENV_DNS_DOMAIN. Later we will check if it is a domain or not  `exit 1`
        DOMAIN="$ENV_DNS_DOMAIN"
      fi
      shift
      ;;

    --subdomain)
      if [ -n "$2" ]; then
        SUBDOMAIN=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        ## check if SUBDOMAIN is a string with letters and numbers and . _ - or not  `exit 1`
        if [[ ! $SUBDOMAIN =~ ^[0-9a-zA-Z\.\-_]+$ ]]; then
          _log "critical" "--subdomain should be a string with letters and numbers and . _ -. Exit"
          exit 1
        fi
        shift
      fi
      shift
      ;;


    -c|--command)
      # Check if an option value is provided
      if [ -n "$2" ]; then
        COMMAND=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        # check if COMMAND is in list of allowed values `exit 1`
        if [[ ! $COMMAND =~ ^(add|recreate|delete_all|delete|delete_one)$ ]]; then
          echo "--command should be in list of allowed values: add|recreate|delete_all|delete_one. Exit"
          exit 1
        fi
        shift
      else
        COMMAND="add"
      fi
      shift
      ;;

    --loglevel)
      # Check if an option value is provided
      if [ -n "$2" ]; then
        LOGLEVEL=$(echo "$2" | sed 's/^"\(.*\)"$/\1/')
        # check if LOGLEVEL is in list of allowed values `exit 1`
        if [[ ! $LOGLEVEL =~ ^(debug|info|warning|critical)$ ]]; then
          _log "critical" "--loglevel should be in list of allowed values: debug|info|warning|critical. Exit"
          exit 1
        fi
        shift
      fi
      shift
      ;;

    *)
      _log "critical"ho "Unknown argument: $1"
      exit 1
      ;;
  esac
done

## if ENV_GODADDY_API_KEY or ENV_GODADDY_API_SECRET is empty, then exit  `exit 0`
if [ -z $API_KEY ] || [ -z $API_SECRET ]; then
  _log "critical" "Set credential ENVs for GoDaddy (ENV_GODADDY_API_KEY, ENV_GODADDY_API_SECRET)!"
  exit 1
fi

## if ENABLE_DNS_MANAGEMENT or STAND or RECORD_NAME is empty, then exit  `exit 0`    
if [ -z $STAND ] || [ -z $RECORD_NAME ] || [ -z $DOMAIN ]; then
  echo -e "Usage: $0 <args>"
  echo -e "\t - -e | --enable: true|false. If enable empty or false, then exit"
  echo -e "\t - ------------------------- Required ---------------------------------" 
  echo -e "\t - -s | --stand: 'string'. \t\t\tRequired"
  echo -e "\t - -r | --record_name: 'string'. \t\tRequired"
  echo -e "\t - -d | --domain: 'string'. \tDefault: ${ENV_DNS_DOMAIN:-none} \tRequired" 
  echo -e "\t - ------------------------- Optional ---------------------------------" 
  echo -e "\t - -c | --command: add(default)|recreate|delete_all|delete|delete_one"
  echo -e "\t - --protocol: 'string beginning with _'. \tDefault: _tcp" 
  echo -e "\t - --service: 'string beginning with _'. \tDefault: _thanosquery"   
  echo -e "\t - -p | --port: 'number'. \tDefault: 10901"     
  echo -e "\t - --ttl: 'number'. \t\tDefault is seconds: 600"  
  echo -e "\t - --priority: 'number'. \tDefault: 0"    
  echo -e "\t - --weight: 'number'. \t\tDefault: 0"    
  echo -e "\t - --subdomain: 'string'. \t\tDefault: prometheus.monitoring" 
  echo -e "\t - --loglevel: debug|info(default)|warning|critical" 

  exit 1
fi


# Print the flag and option values
_log "debug" "Enable DNS management: $ENABLE_DNS_MANAGEMENT"
_log "debug" "Domain: $DOMAIN"
_log "debug" "Subdomain: $SUBDOMAIN"
_log "debug" "Command: $COMMAND"
_log "debug" "Stand: $STAND"
_log "debug" "Record name: $RECORD_NAME"
_log "debug" "Protocol: $PROTOCOL"
_log "debug" "Service: $SERVICE"
_log "debug" "Port: $PORT"
_log "debug" "TTL: $TTL"
_log "debug" "Priority: $PRIORITY"
_log "debug" "Weight: $WEIGHT"
_log "debug" "Loglevel: $LOGLEVEL"


## if ENABLE_DNS_MANAGEMENT empty or false, then exit  `exit 0`
if [ $ENABLE_DNS_MANAGEMENT == false ]; then
  _log "info" "ENABLE_DNS_MANAGEMENT is false. Exit"
  exit 0
fi

## check if DOMAIN is a domain or not  `exit 1`
if [[ ! $DOMAIN =~ ^[a-zA-Z]+\.[a-zA-Z]+$ ]]; then
  _log "critical" "--domain should be a valid domain. Exit"
  exit 1
fi  


DATA="${SUBDOMAIN}.${STAND}.${DOMAIN}"

### functions
_delete_all_records_for_name() {
  _log "info" "delete all records for ${RECORD_NAME}"
  curl -X DELETE https://api.godaddy.com/v1/domains/${DOMAIN}/records/SRV/${RECORD_NAME} \
    -H "Authorization: sso-key ${API_KEY}:${API_SECRET}"
} 

#select command to execute
case $COMMAND in
  add)
    _log "info" "add ${STAND}"
    curl -X PATCH https://api.godaddy.com/v1/domains/${DOMAIN}/records \
      -H "Authorization: sso-key ${API_KEY}:${API_SECRET}" \
      -H 'Content-Type: application/json' \
      --data "[{\"type\": \"SRV\",\"name\": \"${RECORD_NAME}\", \"data\": \"${DATA}\", \"ttl\": ${TTL}, \"port\": ${PORT}, \"priority\": ${PRIORITY}, \"weight\": ${WEIGHT}, \"protocol\": \"${PROTOCOL}\", \"service\": \"${SERVICE}\"}]"
    ;;

  recreate)
    _log "info" "recreate"
    ## 1. delete all records
    _delete_all_records_for_name

    # 2. create new record instead
    _log "info" "delete only one NEW record for ${RECORD_NAME}"
    curl -X PATCH https://api.godaddy.com/v1/domains/${DOMAIN}/records \
      -H "Authorization: sso-key ${API_KEY}:${API_SECRET}" \
      -H 'Content-Type: application/json' \
      --data "[{\"type\": \"SRV\",\"name\": \"${RECORD_NAME}\", \"data\": \"${DATA}\", \"ttl\": ${TTL}, \"port\": ${PORT}, \"priority\": ${PRIORITY}, \"weight\": ${WEIGHT}, \"protocol\": \"${PROTOCOL}\", \"service\": \"${SERVICE}\"}]"
    ;;

  delete_all)
    _log "info" "delete_all"
    _delete_all_records_for_name
    ;;
  
  delete|delete_one)
    _log "info" "delete_one"
    ## 1. get list of all current records
    list=$(curl --silent -X GET https://api.godaddy.com/v1/domains/${DOMAIN}/records/SRV/${SERVICE}.${PROTOCOL}.${RECORD_NAME} \
      -H "Authorization: sso-key ${API_KEY}:${API_SECRET}")
      # echo -e "1 ${list} \n"
    count_of_records=$(echo "${list}" | jq '. | length')
    _log "debug" "1. Got a ${count_of_records:=0} dns SRV records.\n"

    record_exist=$( echo "${list}" | jq --arg STAND "${STAND}" -r '.[]  | select(.data | contains($STAND))')

    
    # 2. if count of elements in list is 0, then exit  `exit 0`
    if [[ $count_of_records -gt 0 ]] && [[ -n $record_exist ]]; then
      ## 2.1  delete all records
      _log "debug" "2.1 Delete all record for ${RECORD_NAME} \n"
      _delete_all_records_for_name

      _log "debug" "2.2\n"
      ## 2.2 add all record exept one current
      for row in $(echo ${list} | jq --arg STAND "${STAND}" -r '.[]  | select(.data | contains($STAND) | not) | @base64'); do
        _jq() {
          echo -e ${row} | base64 -d | jq -r ${1}
        } 

        idata=$(_jq '.')
        # replace srv to SRV in idata
        idata=$(echo ${idata} | sed 's/srv/SRV/g')

        _log "debug"  "recreate one old record $(_jq '.data')\n" 

        curl -X PATCH https://api.godaddy.com/v1/domains/${DOMAIN}/records \
          -H "Authorization: sso-key ${API_KEY}:${API_SECRET}" \
          -H 'Content-Type: application/json' \
          --data "[${idata}]"
      done
    else
      _log "info" "No records found. Exit"
      exit 0
    fi
    ;;
  *)
    _log "critical" "Bad command. Exit"
    exit 1
    ;;
esac

exit 0

