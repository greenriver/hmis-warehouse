require_relative 'rds'

class SqlServerBase < ActiveRecord::Base
  rds = Rds.new

  conf = {
    "adapter"       => "sqlserver",
    "host"          => rds.host,
    "pool"          => 5,
    "timeout"       => 5000,
    "port"          => 1433,
    "username"      => Rds::USERNAME,
    "password"      => Rds::PASSWORD,
    "database"      => rds.database,
    "login_timeout" => 2 # seconds
  }

  establish_connection(conf)

  self.abstract_class = true
end
