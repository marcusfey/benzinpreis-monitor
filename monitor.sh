#!/bin/bash

APIKEY=$(cat apikey)
TELEGRAMBOT=$(cat telegrambot)
TELEGRAMCHATID=$(cat telegramchatid)

set +x

ids=$(cat station_ids  | tr '\n' , | sed s/,*$// )
#echo $ids
raw=$(curl -s  "https://creativecommons.tankerkoenig.de/json/prices.php?ids=$ids&apikey=$APIKEY" ) 
#echo $raw > raw.log
#raw=$(cat raw.log)
prices=$(echo $raw | jq " . |.prices")

echo $prices > prices.log

for id in $(cat station_ids); 
do 
    echo $prices | jq ".\"$id\"" | jq -r "( .status,.\"e5\",.\"e10\", .\"diesel\")" | tr '\n' '\t'  | sed -e s/\t$// > stations/$id.curr

    cmp -s stations/$id.prev stations/$id.curr
    if [[ $? == 0 ]]; then
        echo "same at $id"
    else
        echo "diff at $id: "
        res=$(curl -s "https://creativecommons.tankerkoenig.de/json/detail.php?id=$id&apikey=$APIKEY" )
        echo $res
        name=$(echo $res| jq  -r "(.station.name +\" \"+ .station.street)")
        echo "name:$name"

        text="Benzinpreis-Update:
$name
alt:$(cat stations/$id.prev)
neu:$(cat stations/$id.curr)"
        echo "text: $text"
        curl --silent \
                  --data-urlencode "chat_id=$TELEGRAMCHATID" \
                    --data-urlencode "text=$text" \
                  "https://api.telegram.org/$TELEGRAMBOT/sendMessage"
    
    
    fi

    mv stations/$id.curr stations/$id.prev
done
