# Bopmatic Build Container

The Bopmatic Build Container contains the set of tools, libraries, and
compilers required for creating Bopmatic projects.

## Building

make

## Installing

This container image is published to Docker Hub at
https://hub.docker.com/r/bopmatic/build and can be installed via:

```bash
docker run -i -t --rm --name bopmatic-builder -v $PWD:$PWD -w $PWD bopmatic/build:latest /bin/bash
```

## Usage

TBD

## Contributing
Pull requests are welcome at https://github.com/bopmatic/build-container
For major changes, please open an issue first to discuss what you
would like to change.

## License
[AGPL3](https://www.gnu.org/licenses/agpl-3.0.en.html)
