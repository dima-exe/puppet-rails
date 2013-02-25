# Class: rails::nginx
#
# Create config for nginx for rails application
#
# Parameters:
#   [*application*] - the name of rails application
#
# Requires:
#
#   nginx::site
#
define rails::nginx(
  $application = $name,
){
  nginx::site{ $application:
    content => template('rails/nginx.conf.erb'),
  }
}
