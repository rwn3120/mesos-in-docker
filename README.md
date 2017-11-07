# mesos-in-docker
Run latest Mesos cluster with
* Marathon
* Chronos
* Spark-2.2.0
* Zookeeper (runs separated from master)
with one command on your local machine.

## Requirements
Tested on Ubuntu 17.10 with 
* [Docker](https://www.docker.com/docker-ubuntu) 17.09.0-ce.
* [jq](https://stedolan.github.io/jq) 1.5

## Cluster setup
```
{
  "name": "cluster1",
  "network": {
    "gateway": "172.16.0.254",
    "subnet": "172.16.0.0/16",
    "driver": "bridge",
    "scope": "local"
  },
  "zoo": {
    "peer_port": 2888,
    "leader_port": 3888,
    "nodes": [
      "172.16.1.1",
      "172.16.1.2",
      "172.16.1.3"
    ]
  },
  "masters": [
    "172.16.1.4",
    "172.16.1.5",
    "172.16.1.6"
  ],
  "slaves": [
    "172.16.1.7",
    "172.16.1.8",
    "172.16.1.9",
    "172.16.1.10",
    "172.16.1.11",
    "172.16.1.12"
  ]
}

```

## How to...
###... run cluster
Magic starts with
```
./start.sh [cluster config]
```
Examples:
```
./start.sh conf/cluster.conf
./start.sh                      # same as previous
```
Please note that start.sh scripts edits your /etc/hosts file to provide you an easy access to services.

###... access cluster
With your web browser:
```
http://master1.cluster1.net:5050        # Mesos master
http://master1.cluster1.net:8080/ui     # Marathon 
http://master1.cluster1.net:4400        # Chronos
http://master1.cluster1.net:8081	# Spark
```
With docker exec:
```
docker exec -ti master1.cluster1.net bash
docker exec -ti slave1.cluster1.net bash
```

###... stop cluster
```
./stop.sh [cluster config]
```
Examples
```
./stop.sh conf/cluster.conf
./stop.sh                      # same as previous
```

###... restart cluster
```
./restart.sh [cluster config]
```
Examples
```
./restart.sh conf/cluster.conf
./restart.sh                      # same as previous
```

###... customize and run cluster
```
cp conf/cluster.conf myCluster.conf	# use default config as a template
vim myCluster.conf 			# copy/paste conf/cluster.conf & edit to your taste
./start.sh myCluster.conf		# start your clsuter
```

###... run custom cluster
```
start.sh <path to your json>
```

## Build images
```
./build.sh
```
