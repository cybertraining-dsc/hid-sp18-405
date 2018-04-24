#!/bin/bash
if [ $# -ne 1 ]; then
    worker=1
else
    worker=$1
fi

DESTDIR=Results

echo "starting the containers in swarm mode"
docker stack deploy --compose-file docker-swarm.yml hadoop-sentiment
echo "scale up the service to $worker worker"
docker service scale hadoop-sentiment_worker=$worker

echo "running the sentiment analysis on movie reviews at backend..."
echo "getting physical node that runs master"
nodeID=$(docker stack ps  -f "name=hadoop-sentiment_master.1" --format "{{.Node}}" hadoop-sentiment)
echo $nodeID
s1=${nodeID: -1}
s2=0
if [ "$s1" == "$s2" ]; then
    host="http://149.165.150.80"
else
    host="http://149.165.150.7${nodeID: -1}"
fi


echo "Please look for results at: "
echo "$host:50070"
echo "Please track jobs and resources at : "
echo "$host:8088/cluster"

echo "Please wait for results..."
until curl -f -s "$host:8088/logs/log.txt";
do
    echo "not yet, please wait"
    sleep 30
done

echo "getting the results..."
rm -rf $DESTDIR
wget -r -nH -np -nv -R "index.html*" -R "temp.txt*" -R "time.txt" "$host:8088/logs"
mv logs/ $DESTDIR/

echo "shutting down the service"
./swarm-down.sh
echo "done"
