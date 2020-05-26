# Angular Builder

Serve, test and build Angular projects inside a Docker image.

Includes

1. `google-chrome`
1. `zopfli`
1. `brotli`
1. `node`/`npm`
1. `yarn` (v1.x)

All recent versions (at time of build).

## Usage

Copy the files in `examples` to your project root.   `./run.sh` is the main command, which starts the
docker container with all your project files copied into it. e.g.,

```bash
$ ./run.sh bash
$ ./run.sh ng serve
$ ./run.sh ng test
```

I generally prefer to run each command from the host shell as commands then get saved to the history.

## Compression

After a production build, run

```bash
$ ./run.sh ./compress.sh
```

which does lots of extra compression of assets, specifically with `brotli` and `zopfli`.   You will need to
configure your webserver to server pre-compressed assets.


## Thanks to...

This code includes a copy of `su-exec` from https://github.com/ncopa/su-exec