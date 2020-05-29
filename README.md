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

## New Angular Projects

Here's what I do.

```bash
$ cd ~/Projects
$ ls -s angular-docker-builder/examples/run.sh
$ ./run.sh ng new my-new-prj --skip-git
$ cd my-new-prj
$ git init
$ cp ../angular-docker-builder/examples/* .
$ ./run.sh echo tada
```

`git` inside the docker container doesn't work very well as we don't mount the git credentials.

## Drawbacks

There seem to be relatively few:

1. Most obvious is that some colorization is lost.
1. As above, need `ng new --skip-git` 
1. `yarn` is the default node package manager (easy to change, *per* project)

# MacOS performance

There is a know issue with file performance on Macs.  For example, an 
`npm install` - which might take a minute on Linux - can take 15 on a Mac (at massive CPU).

This probably makes this project at least partially useless for MacOS

## Thanks to...

This code includes a copy of `su-exec` from https://github.com/ncopa/su-exec