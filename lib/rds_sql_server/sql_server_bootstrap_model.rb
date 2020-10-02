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

  if rds.host.present?
    if @did_connect
      begin
        connection.disconnect!
      rescue TinyTds::Error => e
        if e.message ==  'failed to execute statement' # rubocop:disable Metrics/BlockNesting, Style/GuardClause
          puts e.message + ' for disconnecting from SQL Server'
        else
          raise e
        end
      end
    end

    establish_connection(conf) unless ENV['NO_LSA_RDS'].present?
    @did_connect = true
  end

  self.abstract_class = true
end
