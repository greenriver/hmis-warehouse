# Developer Setup for Superset
Superset has become an external dependency for Open Path rather than integrated in the application's docker compose.  The following instructions may help get it running, but are no longer fully accurate, but left here temporarily until updated documentation can be developed.

If you are running on Apple M1 architecture, this may help get superset up and running. Run the following in your `hmis-warehouse` directory.  This will install an abstraction layer that will allow the amd64 version of superset to run on arm64.
```bash
docker run --privileged --rm tonistiigi/binfmt --install amd64
```
In one terminal start up the Superset container.  It is set to start in the background by default, so you may need to `docker compose down` first
```sh
docker compose up superset
```
If all goes well, it'll run through the config and you'll end up with a new
`superset` db on your postgres container.  If it looks like there were any
errors, open a second terminal and run the following:
```sh
docker compose run superset_init_2
```
There's an `init.sh` script in `superset/op/` that only runs if
`superset/op/.did.db.init` doesn't exist. Removing that file will let the
script run again.

At this point the usual `docker compose up -d` should bring up a functional superset installation at http://superset.hmis-warehouse.dev.test.

## Logging in to superset

See @docs/developer/zitadel-idp.md

## References
BinFMT
https://hub.docker.com/r/tonistiigi/binfmt
https://www.reddit.com/r/docker/comments/td0w9t/running_amd64_containers_on_arm64_machine/

Superset on docker
https://github.com/apache/superset/tree/master/docker#readme
https://github.com/apache/superset/blob/master/docker/README.md

https://superset.apache.org/docs/installation/configuring-superset/
