#!/bin/bash

APIKEY=$(cat apikey)
TELEGRAMBOT=$(cat telegrambot)
TELEGRAMCHATID=$(cat telegramchatid)

for id in $(cat station_ids); 
do 
    #curl -s  "https://creativecommons.tankerkoenig.de/json/prices.php?ids=$id&apikey=$APIKEY" | jq ". | .prices|map(.)|.[0]|.\"e5\",.diesel" > stations/$id.curr
    curl -s  "https://creativecommons.tankerkoenig.de/json/prices.php?ids=$id&apikey=$APIKEY" | jq ". | .prices|map(.)|.[0]" > stations/$id.curr
    cmp -s stations/$id.prev stations/$id.curr
    if [[ $? == 0 ]]; then
        echo "same at $id"
    else
        echo "diff at $id: "

        name=$(curl -s "https://creativecommons.tankerkoenig.de/json/detail.php?id=$id&apikey=$APIKEY" | jq ".station.name")

        text="Benzinpreis-Update:
$name
$(cat stations/$id.curr)"
        echo $text
        curl --silent \
                  --data-urlencode "chat_id=$TELEGRAMCHATID" \
                    --data-urlencode "text=$text" \
                  "https://api.telegram.org/$TELEGRAMBOT/sendMessage"
    
    
    fi

    mv stations/$id.curr stations/$id.prev
done
