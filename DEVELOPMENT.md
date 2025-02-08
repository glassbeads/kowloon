# Kowloon development

- [docker-compose based setup](#docker-compose-based-setup)
  - [Architecture overview](#architecture-overview)
  - [Requirements](#requirements)
    - [Docker](#docker)
    - [mkcert](#mkcert)
  - [Setup](#setup)
  - [Usage](#usage)
  - [Caveats](#caveats)

## docker-compose based setup
Benefits:
- consistent environment - same verions of Node, Mongo, etc
- multi-instance out of the box
  - the number of replicas is controlled by a single environment variable
- Mongo admin panel included
- Nginx with certificates included (with a tiny bit of initial setup)
- code hot reloading still works alright, just like with plain `pm2`
- potentially - primary mode of distribution

### Architecture overview
- n Kowloon instances
- 1 Mongo instance, n databases (per each Kowloon instance), 1 Mongo admin user, 1 Kowloon user
- 1 Nginx instance, n configurations (per each Kowloon instance), 1 wildcard certificate
- 1 Mongo-express instance

They get fired up in the following order:
- first: Mongo + container that installs dependencies
- then: all Kowloon instances + mongo-express
- then: Nginx

See `docker-compose.yaml` for details.

Kowloon instances are meant to be accessed via subdomains:
- 1.kowloon.dev
- 2.kowloon.dev
- 3.kowloon.dev
- etc

### Requirements
#### Docker
The infamous containerization engine.  
It comes in two different packages:
- Docker Engine: everything you really need, just a bunch of binaries, but it's not available everywhere
- Docker Desktop: an all-on-one application for desktop, with UI; it's convenient, but heavy, slow, and annoying

Links:
- Mac: Docker Desktop (no alternative) https://docs.docker.com/desktop/setup/install/mac-install/
- Windows:
  - Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/
  - if you're using WSL, you can try to install Docker Engine for Ubuntu on it - https://docs.docker.com/engine/install/ubuntu/
  - binaries: https://docs.docker.com/engine/install/binaries/#install-server-and-client-binaries-on-windows
- Linux:
  - follow installation instructions for your distribution - https://docs.docker.com/engine/install/#supported-platforms
  - or just use their distribution-agnostic "convenience script" - https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script

#### mkcert
A tool that makes generating local certificates easy and convenient. For real, I was surprised too.
- source: https://github.com/FiloSottile/mkcert
- download your binary from: https://github.com/FiloSottile/mkcert/releases/tag/v1.4.4
- execute `./mkcert -install` (or `mkcert.exe -install` if you're on Windows)
- now you're ready to generate local certs

### Setup
You're gonna need to:
1. Create an `.env` file. It can be generated, or created from `.env.example`.
2. Create a wildcard certificate for the  project.  
Once you're done with `mkcert -install`, execute `cd config/nginx/ssl && mkcert '*.kowloon.dev'`.  
That's it! Your local wildcard certificate is ready. All `kowloon.dev` subdomains will be automatically secured with this cert.
3. Make your `kowloon.dev` locally accessible.  
For that, open your `hosts` file (either `/etc/hosts` or `c:\Windows\System32\Drivers\etc\hosts`) with any text editor, and add the following line: `127.0.0.1 1.kowloon.dev 2.kowloon.dev 3.kowloon.dev  # put as many as you have/need`.

### Usage
```sh
# to pull/build all necessary images
docker compose build

# to start the whole thing
docker compose up -d

# to see the status of the whole thing
docker compose ps

# to read all the logs
docker compose logs -f

# to read logs for a specific service
docker compose logs kowloon -f
# this one is convenient if you need to debug something
# instead of `kowloon` it may be any other service - `mongo`, `mongo-express`, `nginx`, whatever
# also, if there are multiple replicas, but you only need logs for one of them, say the 1st one
docker compose logs kowloon -f --index=1

# to open a shell within a service container
docker compose exec kowloon sh
# other commands work too, e.g.
docker compose exec kowloon pm2 status
# may be any other service just as well
# `--index` flag works here too

# to stop the whole thing
docker compose stop

# to stop the whole thing _and_ remove containers
docker compose down
# removing containers is safe, it does not remove anything valuable, like code or data

# to _quickly_ stop/remove the whole thing
docker compose kill && docker compose down

# to recreate/restart a specific service
docker compose rm -sf kowloon && docker compose up -d --no-recreate
# note that it won't recreate e.g. database, see below for that

# if you ever need to remove volumes, e.g. you need to wipe Mongo clean and start from scratch
docker volume rm -f kowloon_mongo
# or all of them, indiscriminately
docker volume prune -fa
# note that you can't remove volumes without removing containers first (see above)
```

### Caveats
1. Multi-instance: once initial setup has happened, adding more Kowloon replicas (by increasing `REPLICAS` environment variable) won't generate databases for those replicase automatically.  
This is because of how `mongo` image works: initialization scripts only get executed during initial setup.  
In case you ever need it, you can always go to the mongo-express panel (http://localhost:27117) and create the database manually from there.  
Alternatively, you may just remove the volume (see the last couple commands above) and start over; but maybe not, if losing accumulated data isn't an option.
