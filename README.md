# redpubsub

Push events to consumer using OpenResty + Redis.

## Examples

*Subscribe to id1 and id2 on 'footopic'.*

```
curl -H "Accept: text/event-stream" http://redpubsub.xyz/sub/footopic/id1,id2
```

*Write json to id1 on footopic.*

```
curl -X POST -d '{"data":"value"}' http://redpubsub.xyz/pub/footopic/id1
```

## Architecture

Consumers subscribe to list of N topics and each connection looks like:

```
Consumer => (http) => OpenResty => (multiple subscribes over 1 tcp socket) => Redis
```

When a consumer connects they will receive the most recent message on the relevant topics.

## Why?

This is not the most performant way of pushing to N consumers (putting full consumer load onto Redis), but it can be scaled and it is architecturally very simple.

## Running

```
/usr/local/openresty/nginx/sbin/nginx -p .

# or with docker (host networking to access local redis for now)

docker build -t redpubsub .
docker run -it --net=host redpubsub

```

