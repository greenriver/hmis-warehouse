# Must connect to "master" database to create the writable database we'll use
class SqlServerBootstrapModel < ActiveRecord::Base
  rds = Rds.new

  conf = {
    "adapter"       => "sqlserver",
    "host"          => rds.host,
    "pool"          => 5,
    "timeout"       => 50_000,
    "port"          => 1433,
    "username"      => Rds::USERNAME,
    "password"      => Rds::PASSWORD,
    "database"      => 'master',
    "login_timeout" => 2, # seconds
    "sslmode"      => 'verify-full',
    "sslcert"      => 'config/cacert.pem'
  }

  establish_connection(conf)

  self.abstract_class = true
end
