## Bitgo wallet configuration

1. Login to your bitgo account
2. Click in create wallet button
![scheme](images/create_wallet.png)
3. Choose wallet for appropriate currency
![scheme](images/choose_wallet.png)
4. Setup your wallet
![scheme](images/setup_wallet.png)
5. Put name of your wallet
![scheme](images/wallet_name.png)
6. Put password of your wallet
![scheme](images/wallet_secret.png)
P.S. You should save this password for future wallet configuration

## Peatio BITGO wallet configuration

1. Go to tower admin panel Settings -> Wallets -> Add wallet
* Uri == Bitgo service URI
* Secret == Wallet password
* Bitgo Wallet Id
![scheme](images/wallet_id.png)
* Bitgo Access Token
![scheme](images/wallet_access_token.png)
![scheme](images/create_wallet_access_token.png)
![scheme](images/access_token.png)

## Webhook configuration

![scheme](images/webhook.png)
![scheme](images/webhook_creating.png)

Where url should be "https://{host_url}/api/v2/peatio/public/webhooks/{event}"

* For deposit wallets event should be 'deposit'
* For hot wallets event should be 'withdraw'