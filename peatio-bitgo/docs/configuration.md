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

* Uri == http://prod-coinhub-coinhub.prod-backend/api/v2

* Secret == Wallet password

* Bitgo Wallet Id

* Blockchain == bitgo-mainnet (unless it's presented - create, setting any values, only name is important)

![scheme](images/wallet_id.png)

* Bitgo Access Token

The BitGo Access Token works as an API that once imported into Cryptio will let you track your balances and past transactions, and it will automatically update.

If you are updating the password of your wallets/account, you need to change it as well.

To obtain an Access Token / API key from BitGo, follow the steps :

1. Navigate to the Account Settings page.

2. Navigate to the Develop Options section.

3. Choose the Access Token option - Create a long-lived API Access tokens

To create a BitGo Access Token (API Key), follow these steps:

Give a name to your token.
Grant View, Spend, Create Wallets permissions
Set Lifetime spending limits
Add IP addresses allowed ()

![scheme](images/wallet_access_token.png)
![scheme](images/create_wallet_access_token.png)
![scheme](images/access_token.png)

## Webhook configuration

Create a webhook for each of your wallets

![scheme](images/webhook.png)
![scheme](images/webhook_creating.png)

Where url should be "https://{host_url}/api/v2/peatio/public/webhooks/{event}"

* For deposit wallets event should be 'deposit'

* For hot wallets event should be 'withdraw'