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
bundle install
rails db:create && rails db:migrate && rails db:seed
rails s
```

## Environment variables

`TWITTER_KEY`: twitter api key
`TWITTER_SECRET`: twitter api secret
