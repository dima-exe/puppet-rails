# Class: rails::application

#
# Setup env for application
#   * create user
#   * create directory structure for deploy
#   * install rbenv & ruby
#   * generate database.yml and unicorn.rb
#   * install runit and create supervisor for application
#
# Parameters:
#   [*application*]   - the name of application
#   [*ruby*]          - rbenv version  of ruby
#   [*keys*]          - public ssh keys
#   [*num_instances*] - num unicorn instances to run
#   [*rails_env*]
#   [*db_adapter*]
#   [*db_user*]
#   [*db_password*]
#   [*db_host*]
#   [*db_pool*]
#
# Requires:
#
#   rbenv::ruby
#

define rails::application(
  $application         = $name,
  $ruby                = undef,
  $keys                = undef,
  $rails_env           = 'production',
  $app_user            = $name,
  $db_adapter          = undef,
  $db_user             = $name,
  $db_password         = $name,
  $db_host             = 'localhost',
  $db_pool             = 5,
  $num_instances       = 2,
){

  include 'runit'

  $deploy_path = '/u/apps'
  $deploy_to = "${deploy_path}/${application}"

  if $ruby != undef {
    rbenv::ruby{ $ruby: }
  }

  rails::deploy{ $application:
    keys        => $keys,
    deploy_path => $deploy_path,
    app_user    => $app_user,
  }

  if $db_adapter != undef {
    file{ "${deploy_to}/shared/config/database.yml":
      ensure     => 'present',
      owner      => $app_user,
      content    => template('rails/database.yml.erb'),
      require    => File["${deploy_to}/shared/config"]
    }
  }

  file{ "${deploy_to}/shared/config/unicorn.rb":
    ensure     => 'present',
    owner      => $app_user,
    content    => template('rails/unicorn.rb.erb'),
    require    => File["${deploy_to}/shared/config"]
  }

  runit::service { $application:
    user       => $app_user,
    group      => $app_user,
    rundir     => "${deploy_to}/services",
    command    => "runsvdir ${deploy_to}/services/current",
    require    => File["${deploy_to}/services"]
  }
}
