[root@ecbplxtip3 mon_stg]# cat monDS.sh
#!/bin/sh
#
#  Script %name:        monDS.sh%
#  %version:            1 %
#  Description:
# =========================================================================================================
#  %created_by:         Diego Villegas (FDM) %
#  %date_created:       Sat May 28 12:19:02 ECT 2019 %
# =========================================================================================================
# change log
# =========================================================================================================
# Mod.ID         Who                            When                                    Description
# =========================================================================================================
# =========================================================================================================

#Definicion de variables.

HOSTNAME=`uname -n`
FECHA=`date +%Y-%m-%dT`
DATE=`date +%Y/%m/%d,%H-%M-%S`
TIME=`date +%H:%M:%S-0700`
CONFDIR="/scripts/mon_stg"
CONFFILE="/scripts/mon_stg/storage.conf"
TIMEOUT_ERR="No JSON object could be decoded"

eventos(){
SEVERITY=$1
    for i in `cat $CONFFILE | grep "PRIMARY"`;
    do
        STG_NAME=`echo $i | awk -F: '{print $2}'`
        STG_IP=`echo $i | awk -F: '{print $3}'`
        TOKEN=`curl --tlsv1 -k -H "Content-Type: application/json" -X POST -d '{request:{params:{username:USER,password:PASSWORD}}}' https://$STG_IP:8452/api/v1/tokens | python -m json.tool| grep -i '"token": "' | awk -F: '{print $2}'|sed 's/ //g'|sed 's/"//g'`
        curl --tlsv1 -k -H "Content-Type: application/json" -H "X-Auth-Token:$TOKEN" -X GET "https://$STG_IP:8452/api/v1/events?severity=$SEVERITY&before=$FECHA$TIME"|python -m json.tool | grep "description" | sed 's/,//g'|sed 's/"//g'| awk -F: '{print $2}' > $CONFDIR/temporal.out
                NUM=`cat $CONFDIR/temporal.out | wc -l|tr -d ' '`
                if [ $NUM -eq 1 ]
                then
                    DESCRIPTION=`cat $CONFDIR/temporal.out`
            if [ "$DESCRIPTION" != "" ]
            then
                    echo "$DATE:$STG_NAME:$STG_IP:$DESCRIPTION:$1">>$CONFDIR/eventos.txt
            fi
                else
                    while read p; do
                                echo "$DATE:$STG_NAME:$STG_IP:$p:$1">>$CONFDIR/eventos.txt
            done < temporal.out
                fi
    done
}

eventos "error"
eventos "warning"
