# Class: rails::deploy
#
# Sets up basic requirements for a deploy:
#   * user to run the application as
#   * create directory to deploy app to
#
# Does not handle creating current, releases or shared directories. Capistrano
# already handles that.
#
# Parameters:
#   [*app_name*]    - name of the application. Used in the default $deploy_path,
#                     "/u/apps/${app_name}". Defaults to the name of the
#                     resource.
#   [*deploy_path*] - where the application will be deployed. Defaults to
#                     '/u/apps'
#   [*app_user*]    - name of the system user to create to run the application
#                     as. Defaults to 'deploy'
#   [*deploy_keys*] - public ssh keys
#
# Requires:
#
# Sample Usage:
#   rails::deploy { 'todo-list':
#     app_user => 'passenger',
#     deploy_path => '/var/lib/passenger,
#   }
#

define rails::deploy(
  $app_name    = $name,
  $deploy_path = '/u/apps',
  $app_user    = $name,
  $deploy_keys = undef,
) {

  $app_deploy_path = "${deploy_path}/${app_name}"

  user { $app_user :
    ensure     => present,
    system     => true,
    managehome => true,
    shell      => '/bin/bash',
    home       => "/home/${app_user}",
  }

  group { $app_user :
    ensure     => present,
    require    => User[$app_user],
  }

  if $deploy_keys != undef {
    ssh_authorized_key { "${app_user}_deploy_keys":
      ensure => 'present',
      key    => $deploy_keys,
      type   => 'ssh-rsa',
      user   => $app_user
    }
  }

  exec { "rails:${app_name}:dir":
    command    => "/bin/mkdir -p ${app_deploy_path}",
    creates    => $app_deploy_path,
  }

  file { $app_deploy_path:
    ensure     => directory,
    owner      => $app_user,
    mode       => '1775',
    require    => [User[$app_user], Exec["rails:${app_name}:dir"]]
  }

  file { ["${app_deploy_path}/releases",
          "${app_deploy_path}/shared",
          "${app_deploy_path}/services"]:
    ensure     => directory,
    owner      => $app_user,
    mode       => '1775',
    require    => File[$app_deploy_path]
  }

  file { ["${app_deploy_path}/shared/config",
          "${app_deploy_path}/shared/log",
          "${app_deploy_path}/shared/pids"]:
    ensure     => directory,
    owner      => $app_user,
    mode       => '1775',
    require    => File["${app_deploy_path}/shared"]
  }

  file { "${app_deploy_path}/shared/config/settings":
    ensure     => directory,
    owner      => $app_user,
    require    => File["${app_deploy_path}/shared/config"]
  }
}
