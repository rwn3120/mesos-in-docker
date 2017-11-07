#!/bin/bash
curl -X POST -d@"pi.json"  --header "Content-Type:application/json;charset=UTF-8" "http://master1.cluster1.net:7077/v1/submissions/create"
