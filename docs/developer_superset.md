# Developer Setup for Superset
This may be completely unneccesary in an amd64 architecture, but the following was helpful getting superset up and running on arm64 (Apple M1).

Run the following in your `hmis-warehouse` directory.  This will install an abstraction layer that will allow the amd64 version of superset to run on arm64.
```bash
docker run --privileged --rm tonistiigi/binfmt --install amd64
```
In one terminal start up the Superset container.  It is set to start in the background by default, so you may need to `docker-compose down` first
```sh
docker-compose up superset
```
If all goes well, it'll run through the config and you'll end up with a new `superset` db on your postgres container.  If it looks like there were any errors, open a second terminal and run the following:
```sh
docker-compose exec superset bash
superset db upgrade
superset fab create-admin --username admin --password admin --firstname Super --lastname Admin --email admin@greenriver.com
superset load_examples
superset init
```

At this point the usual `docker-compose up -d` should bring up a functional superset installation at http://superset.hmis-warehouse.dev.test.

## References
BinFMT
https://hub.docker.com/r/tonistiigi/binfmt
https://www.reddit.com/r/docker/comments/td0w9t/running_amd64_containers_on_arm64_machine/

Superset on docker
https://github.com/apache/superset/tree/master/docker#readme
https://github.com/apache/superset/blob/master/docker/README.md

https://superset.apache.org/docs/installation/configuring-superset/
