# Must connect to "master" database to create the writable database we'll use
class SqlServerBootstrapModel < ActiveRecord::Base
  rds = Rds.new
  cert_path = ENV['RDS_CERT_PATH'].presence || '/etc/ssl/certs/us-east-1-bundle.pem'

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
        Timeout.timeout(15) do
          connection.disconnect!
        end
      rescue TinyTds::Error, Timeout::Error => e
        Rails.logger.warn "Couldn't cleanly disconnect from a previous SqlServer. Server might already be gone: #{e.message}"
      end
    end

    establish_connection(conf) unless ENV['NO_LSA_RDS'].present?
    @did_connect = true
  end

  self.abstract_class = true
end
