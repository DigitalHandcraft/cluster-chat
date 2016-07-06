# Reference of cluster-chat

## First

Assume that cluster-chat server is listening on 0.0.0.0:3000;

```
$ bin/cluster-chat 0.0.0.0 3000
```

Then, please connect to the chat-server from your application or a websocket-cleint.  
For instance, if you can use [wscat](https://github.com/websockets/wscat) as a client;

```
$ wscat -c ws://localhost:3000
```

After establishing a connection, you should send "*Join*" message first.

## To Disconnect

It's simple. All you should do is kill your connection.

## Message Format