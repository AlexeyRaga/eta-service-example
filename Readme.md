# Eta: Kafka client example

This example demonstrates how to use Kafka bindings for [Eta](http://eta-lang.org).
Libraries that are used and demonstrated in this project:
- [Kafka client](https://github.com/haskell-works/eta-kafka-client)
- [Kafka client conduit](https://github.com/haskell-works/eta-kafka-conduit)
- [Avro](https://github.com/haskell-works/hw-haskell-avro) (Native Haskell implementation for [Avro](https://avro.apache.org/docs/current/) serialization patched for Eta)

## Project description

The example simulates an overly simplified chat system:

The **producer** reads messages from the console, formats them as [Avro](https://avro.apache.org/docs/current/) (a popular serialization format that is often used with Kafka) and writes to a given Kafka topic.

The **consumer** reads messages from a given Kafka topic, decodes them from Avro and prints them in console.

## Running locally
For this example you should have 3 components running:
1. Kafka broker
2. Producer service
2. Consumer service

### Start Kafka
If you don't have Kafka installed and running use `docker-compose` configuration provided with this example:

```
$ DOCKER_IP=<your real ip address> docker-compose up -d
```

(note that `DOCKER_IP` should point to your real IP address and not to `127.0.0.1`).

### Start producer service
Open a new terminal and start `producer`:

```
$ etlas run producer -- --kafka-broker <your ip address>:9092 --input-topic simple-chat
```

### Start consumer service
Open a new terminal and start `consumer`:

```
etlas run consumer -- --kafka-broker <your ip address>:9092 --input-topic simple-chat
```

### Send some messages
In `producer` terminal start typing messages (one per line). The messages should appear in the `consumer` terminal.

You can also use `@user message` format to make it a bit more interesting :)