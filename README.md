# gc-me

A [GoCardless Pro](https://gocardless.com/pro/) [Slack](https://slack.com/) integration.

To authorise `gc-me` to create payments on your behalf, in Slack:

> /gc-me authorise

To add a new customer (sends them an email with a redirect flow link)

> /gc-me add new-customer@example.com

To take a payment from one of your existing customers:

> /gc-me £10 from my-existing-customer@example.com

## Todo

- add/manage customers via slack username
