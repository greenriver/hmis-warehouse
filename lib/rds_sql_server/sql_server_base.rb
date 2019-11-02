class SqlServerBase < ActiveRecord::Base
  rds = Rds.new

  conf = {
    'adapter' => 'sqlserver',
    'host' => rds.host,
    'pool' => 5,
    'timeout' => Rds.timeout,
    'port' => 1433,
    'username' => Rds::USERNAME,
    'password' => Rds::PASSWORD,
    'database' => rds.database,
    'login_timeout' => 2, # seconds
    'sslmode' => 'verify-full',
    'sslcert' => 'config/cacert.pem',
  }

  establish_connection(conf) unless ENV['NO_LSA_RDS'].present?

  self.abstract_class = true
end
