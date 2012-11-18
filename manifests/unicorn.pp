# Class: rails::unicorn
#
# Basic setup for running a unicorn web server/service.
#
# Parameters:
#   [*app_name*]       - Name of the application. Defaults to the resource name.
#   [*app_user*]       - User to run the application as. Defaults to 'deploy'.
#                        Passed down to rails::deploy to create the user
#   [*deploy_path*]    - Path where the application(s) are deployed. Defaults to
#                        '/u/apps'.
#                        Passed down to rails::deploy to create the directory.
#   [*pid_path*]       - Path to the unicorn PID file.  Defaults to
#                        "${deploy_path}/${app_name}/tmp".
#   [*config_path*]    - Path to the unicorn config.  Defaults to
#                        "${deploy_path}/${app_name}/config".
#   [*bundle*]         - Whether unicorn is bundled with your application.  Affects
#                        the generated init script. Defaults to true.
#
# Requires:
#
# Sample usage:
#
#   rails::unicorn { 'my-app-name':
#     app_user       => 'rails',
#     deploy_path    => '/opt/apps',
#     pid_path       => '/var/run',
#     config_path    => '/etc/unicorn',
#   }
#
define rails::unicorn(
  $app_name     = $name,
  $app_user     = 'deploy',
  $deploy_path  = "/u/apps/${app_name}",
  $pid_path     = "${deploy_path}/${app_name}/tmp",
  $config_path  = "${deploy_path}/${app_name}/config",
  $bundle       = true,
  $bundler_path = ''
) {

  $app_root = "${deploy_path}/${app_name}"

  rails::deploy { $app_name :
    app_user    => $app_user,
    deploy_path => $deploy_path,
  }

  file { "unicorn-init-${app_name}":
    ensure  => present,
    path    => "/etc/init.d/unicorn-${app_name}",
    content => template('rails/unicorn-init.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service["unicorn-${app_name}"],
  }

  # We don't start the service yet since we'll have to deploy code first via
  # some other tool (puppet, capistrano, etc). That service should also be able
  # to start the application. This is to ensure it is running after server restart.
  service { "unicorn-${app_name}":
    enable    => true,
    hasstatus => false,
    require   => Rails::Deploy[$app_name],
  }
}
