# osv-neo4j
Run Neo4J server with OSv on the cloud.

### Requirements

###### Install `qemu`.

For OSX:
```shell
brew install qemu
export CAPSTAN_QEMU_PATH=/usr/local/Cellar/qemu/2.5.0_2/bin/qemu-system-x86_64
```

###### Install Capstan

[Capstan](http://osv.io/capstan/) will actually build the image for you.


### Config

The `config.sh` script is used to configure your neo4j instance before building
the OSv image. Either replace the script or set the environment variables as
you need.

### Build OSv Image

```shell
make build
```

### Test neo4j locally

If you previously built the image, remove it with `capstan delete osv-neo4j`

Build a new image with:

```shell
capstan run osv-neo4j
```

You should see something like

```
Created instance: osv-neo4j
OSv v0.24
eth0: 10.0.2.15
2016-06-07 19:32:24.202+0000 INFO  No SSL certificate found, generating a self-signed certificate..
2016-06-07 19:32:25.095+0000 INFO  Starting...
2016-06-07 19:32:26.857+0000 INFO  Initiating metrics...
WARNING: fcntl(F_SETLK) stubbed
2016-06-07 19:32:32.266+0000 INFO  Started.
2016-06-07 19:32:32.647+0000 INFO  Mounted REST API at: /db/manage
2016-06-07 19:32:34.446+0000 INFO  Remote interface available at http://0.0.0.0:7474/
```
