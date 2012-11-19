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
  $deploy_path = '/u/apps/',
  $app_user    = 'deploy',
  $public_key  = '<EMPTY>',
  $private_key = '<EMPTY>',
) {

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

  file{ "/home/${app_user}/.ssh":
    ensure  => 'directory',
    mode    => '0700',
    owner   => $app_user,
    group   => $app_user,
    require => User[$app_user]
  }

  if $private_key != '<EMPTY>' {
    file{ "/home/${app_user}/.ssh/id_rsa":
      ensure  => 'present',
      mode    => '0600',
      owner   => $app_user,
      group   => $app_user,
      content => $private_key,
      require => File["/home/${app_user}/.ssh"]
    }
  }

  if $public_key != '<EMPTY>' {
    file{ "/home/${app_user}/.ssh/id_rsa.pub":
      ensure  => 'present',
      mode    => '0644',
      owner   => $app_user,
      group   => $app_user,
      content => $public_key,
      require => File["/home/${app_user}/.ssh"]
    }

    file{ "/home/${app_user}/.ssh/authorized_keys":
      ensure  => 'present',
      mode    => '0644',
      owner   => $app_user,
      group   => $app_user,
      content => $public_key,
      require => File["/home/${app_user}/.ssh"]
    }
  }

  exec { 'create_rails_deploy_path':
    command    => "/bin/mkdir -p ${deploy_path}/${app_name}",
    unless     => "/usr/bin/test -d ${deploy_path}/${app_name}"
  }

  file { "${deploy_path}/${app_name}":
    ensure     => directory,
    owner      => $app_user,
    group      => $app_user,
    mode       => '1775',
    require    => [User[$app_user], Exec['create_rails_deploy_path']]
  }

  file { ["${deploy_path}/${app_name}/releases",
          "${deploy_path}/${app_name}/shared",
          "${deploy_path}/${app_name}/services"]:
    ensure     => directory,
    owner      => $app_user,
    group      => $app_user,
    mode       => '1775',
    require    => File["${deploy_path}/${app_name}"]
  }

  file { "${deploy_path}/${app_name}/services/current":
    ensure     => directory,
    owner      => $app_user,
    group      => $app_user,
    require    => File["${deploy_path}/${app_name}/services"]
  }

  file { "${deploy_path}/${app_name}/shared/config":
    ensure     => directory,
    owner      => $app_user,
    group      => $app_user,
    require    => File["${deploy_path}/${app_name}/shared"]
  }

  file { "${deploy_path}/${app_name}/shared/config/settings":
    ensure     => directory,
    owner      => $app_user,
    group      => $app_user,
    require    => File["${deploy_path}/${app_name}/shared/config"]
  }
}
