# Class: rails::database
#
# Setup database server for rails application
#   * install mysql or postgresql server, dependent of $db_adapter
#   * create user and grant privileges
#   * create database[s]
#
# Parameters:
#   [*application*] - the name of rails application
#   [*rails_env*]   - Rails.env
#   [*db_adapter*]  - database adapter, supported  mysql2 and postgresql
#   [*db_user*]
#   [*db_password*]
#   [*db_host*]
#   [*databases*]
#
# Requires:
#
#   postgresql::server
#   mysql::server
#

define rails::database(
  $application         = $name,
  $rails_env           = 'production',
  $db_adapter          = undef,
  $db_user             = $name,
  $db_password         = $name,
  $db_host             = 'localhost',
  $databases           = undef,
){
  if $databases == undef {
    $apply_databases = ["${$application}_${$rails_env}"]
  } else {
    $apply_databases = $databases
  }

  case $db_adapter {
    'mysql2': {
      require 'mysql::server'

      $mysql_db_user = $db_host ? {
        'localhost' => "${db_user}@localhost",
        default     => "${db_user}@%"
      }

      database_user{ $mysql_db_user:
        password_hash => mysql_password($db_password),
        require       => Class['mysql::config']
      }

      database_grant{ $mysql_db_user:
        privileges    => ['all'],
        require       => Database_user[$mysql_db_user]
      }

      database { $apply_databases:
        ensure  => 'present',
        charset => 'utf8',
        require => Database_user[$mysql_db_user]
      }

    }
    'postgresql': {
      require 'postgresql::server'

      postgresql::database{ $apply_databases:
        require => Class['postgresql::config'],
      }

      postgresql::role{ $db_user:
        password_hash => postgresql_password($db_user, $db_password),
        superuser     => true,
        login         => true,
        createdb      => true,
        require       => Class['postgresql::config'],
      }
    }

    default: {}
  }
}
