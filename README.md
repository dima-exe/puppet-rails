# puppet-rails

Allows you to manage your Rails deploys.

## Setup environment

Use the `rails::deploy` resource type to add your application user and create
your deploy path:

```puppet
rails::deploy { 'my-app-name':
  deploy_path => '/var/www/rails',
  app_user => 'rails',
}
```


