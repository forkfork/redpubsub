# redpubsub

Push events to consumer using OpenResty + Redis.

Example 1: subscribe to id1 and id2 on 'footopic'.

curl -H "Accept: text/event-stream" http://redpubsub.xyz/sub/footopic/id1,id2

Example 2: write json to id1 on footopic.

curl -X POST -d '{"data":"value"}' http://redpubsub.xyz/pub/footopic/id1

Consumers subscribe to list of N topics, each connection looks like:

```
Consumer => (http) => OpenResty => (multiple subscribes over 1 tcp socket) => Redis
```

When a consumer connects they will receive the most recent message.
