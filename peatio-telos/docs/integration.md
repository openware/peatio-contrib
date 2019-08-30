# Integration.

For Peatio Telos plugin integration you need to do the following steps:

## Image Build.

1. Add peatio-telos gem into your Gemfile.plugin
```ruby
gem 'peatio-telos', '~> 0.1.0'
```

2. Run `bundle install` for updating Gemfile.lock

3. Build custom Peatio [docker image with Telos plugin](https://github.com/rubykube/peatio/blob/master/docs/plugins.md#build)

4. Push your image using `docker push`

5. Update your deployment to use image with peatio-telos gem

## Peatio Configuration.

1. Create EOS Blockchain [config example](../config/blockchains.yml).
    * In EOS blockchain blocks goes very fast, so to don't fall behind with blocks from your node we recommend to set step at least to 50 and confirmations at least to 20

2. Create EOS Currency [config example](../config/currencies.yml).
    * No additional steps are needed

3. Create EOS Wallets [config example](../config/wallets.yml)(deposit and hot wallets are required).
    * Be sure that you have telos_token_name option filled even for EOS currency itself
    * We need to communicate with ktelosd to sign transaction, ktelosd is running on non default telos port which is 8900 and passed to json_rpc function when we sign
    transaction
