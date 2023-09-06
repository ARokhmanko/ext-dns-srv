#!/bin/bash

# #add code for catching SIGTERM signal
_function_sigterm() {
    echo "Got SIGTERM signal in DNS SRV service"
    echo "Delete current DNS SRV record"
    #pass arguments to dns-srv-mgmt.sh  via @
    echo "./dns-srv-mgmt.sh -c delete_one -e $@"
    ./dns-srv-mgmt.sh -c delete_one -e $@
    exit 0
}
## pass params to function _function_sigterm
trap '_function_sigterm "$@"' SIGTERM

while true; 
do
    echo -e "./dns-srv-mgmt.sh -c add -e $@ \n" 
    ./dns-srv-mgmt.sh -c add -e $@

    ## exit $? is the return value not 0 of the last command executed
    if [ $? -ne 0 ]; then
        echo "DNS SRV record return error"
        exit 1
    fi

    
    sleep ${ENV_DNS_SRV_TIMEOUT:-60}
done

