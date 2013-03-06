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
#   [*keys*]          - public ssh keys
#   [*num_instances*] - num unicorn instances to run
#   [*rails_env*]
#   [*db_adapter*]
#   [*db_user*]
#   [*db_password*]
#   [*db_host*]
#   [*db_pool*]
#   [*resque_url*]
#
# Requires:
#
#   rbenv::ruby
#

define rails::application(
  $application         = $name,
  $deploy_keys         = undef,
  $rails_env           = 'production',
  $app_user            = $name,
  $db_adapter          = undef,
  $db_user             = $name,
  $db_password         = $name,
  $db_host             = 'localhost',
  $db_pool             = 5,
  $num_instances       = 2,
  $resque_url          = undef,
){

  include 'runit'

  $deploy_path = '/u/apps'
  $deploy_to = "${deploy_path}/${application}"

  rails::deploy{ $application:
    deploy_keys => $deploy_keys,
    deploy_path => $deploy_path,
    app_user    => $app_user,
  }

  if $db_adapter != undef {
    file{ "${deploy_to}/shared/config/database.yml":
      ensure  => 'present',
      owner   => $app_user,
      content => template('rails/database.yml.erb'),
      mode    => '0640',
      require => File["${deploy_to}/shared/config"]
    }
  }

  if $resque_url != undef {
    file{ "${deploy_to}/shared/config/resque.yml":
      ensure  => 'present',
      owner   => $app_user,
      mode    => '0640',
      content => template('rails/resque.yml.erb'),
      require => File["${deploy_to}/shared/config"]
    }
  }

  file{ "${deploy_to}/shared/config/unicorn.rb":
    ensure  => 'present',
    owner   => $app_user,
    mode    => '0640',
    content => template('rails/unicorn.rb.erb'),
    require => File["${deploy_to}/shared/config"]
  }

  runit::service { $application:
    user       => $app_user,
    group      => $app_user,
    rundir     => "${deploy_to}/services",
    command    => "runsvdir ${deploy_to}/services/current",
    require    => File["${deploy_to}/services"]
  }
}
