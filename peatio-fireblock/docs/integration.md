# Integration.

For Peatio fireblock plugin integration you need to do the following steps:

## Image Build.

1. Add peatio-fireblock gem into your Gemfile.plugin
```ruby
gem 'peatio-fireblock', '~> 0.1.0'
```

2. Run `bundle install` for updating Gemfile.lock

3. Build custom Peatio [docker image with fireblock plugin](https://github.com/rubykube/peatio/blob/master/docs/plugins.md#build)

4. Push your image using `docker push`

5. Update your deployment to use image with peatio-fireblock gem

<!-- ## Peatio Configuration.

1. Create fireblock Blockchain [config example](../config/blockchains.yml).
    * No additional steps are needed

2. Create fireblock Currency [config example](../config/currencies.yml).
    * No additional steps are needed

3. Create fireblock Wallets [config example](../config/wallets.yml)(deposit and hot wallets are required).
    * No additional steps are needed -->
