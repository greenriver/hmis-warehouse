# Must connect to "master" database to create the writable database we'll use
class SqlServerBootstrapModel < ActiveRecord::Base
  rds = Rds.new
  cert_path = ENV['RDS_CERT_PATH'].presence || '/etc/ssl/certs/rds-combined-ca-bundle.pem'

  conf = {
    'adapter' => 'sqlserver',
    'host' => rds.host,
    'pool' => 5,
    'timeout' => 50_000,
    'port' => 1433,
    'username' => Rds::USERNAME,
    'password' => Rds::PASSWORD,
    'database' => 'master',
    'login_timeout' => 2, # seconds
    'sslmode' => 'verify-full',
    'sslcert' => cert_path,
  }

  establish_connection(conf) unless ENV['NO_LSA_RDS'].present?

  self.abstract_class = true
end
