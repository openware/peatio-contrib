# Integration.

For Peatio bitgo plugin integration you need to do the following steps:

## Image Build.

1. Add peatio-bitgo gem into your Gemfile.plugin
```ruby
gem 'peatio-bitgo', '~> 0.1.0'
```

2. Run `bundle install` for updating Gemfile.lock

3. Build custom Peatio [docker image with bitgo plugin](https://github.com/rubykube/peatio/blob/master/docs/plugins.md#build)

4. Push your image using `docker push`

5. Update your deployment to use image with peatio-bitgo gem

## Peatio Configuration.

1. Create bitgo Blockchain [config example](../config/blockchains.yml).
    * No additional steps are needed

2. Create bitgo Currency [config example](../config/currencies.yml).
    * No additional steps are needed

3. Create bitgo Wallets [config example](../config/wallets.yml)(deposit and hot wallets are required).
    * No additional steps are needed
