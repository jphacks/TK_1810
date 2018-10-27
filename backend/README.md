# README

Backend server for the product.

## Basic configuration

- `ruby`: `2.5.1`
- `rails`: `5.2.1`
- `puma`
- `pg`


## Getting started

```
git clone git@gitlab.com:mutekikantai/backend.git
```

You can easily start using `docker-compose`.

```
script/init
docker-compose up -d
```

If `docker-compose` is not available on your machine, you can also start in normal way.

```
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails s
```

## Environment variables

`TWITTER_KEY`: twitter api key

`TWITTER_SECRET`: twitter api secret
