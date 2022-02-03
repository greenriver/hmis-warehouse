class SqlServerBase < ActiveRecord::Base
  rds = Rds.new
  cert_path = ENV['RDS_CERT_PATH'].presence || '/etc/ssl/certs/rds-combined-ca-bundle.pem'

  conf = {
    'adapter' => 'sqlserver',
    'host' => rds.host,
    'pool' => 5,
    'timeout' => Rds.timeout,
    'idle_timeout' => 10_000,
    'port' => 1433,
    'username' => Rds::USERNAME,
    'password' => Rds::PASSWORD,
    'database' => rds.database,
    'login_timeout' => 2, # seconds
    'sslmode' => 'verify-full',
    'sslcert' => cert_path,
  }

  # disconnect! complains if there's no host, oddly.
  if rds.host.present?
    # Only need to disconnect after the first connection
    if @did_connect && ! rds.static_rds?
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
