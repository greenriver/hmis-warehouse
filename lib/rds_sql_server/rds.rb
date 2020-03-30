# https://docs.aws.amazon.com/sdkforruby/api/index.html
# https://docs.aws.amazon.com/sdkforruby/api/Aws/RDS.html

require 'aws-sdk'

class Rds
  attr_accessor :client, :identifier

  REGION             = 'us-east-1'.freeze
  AVAILABILITY_ZONE  = 'us-east-1e'.freeze
  ACCESS_KEY_ID      = ENV.fetch('RDS_AWS_ACCESS_KEY_ID')
  SECRET_ACCESS_KEY  = ENV.fetch('RDS_AWS_SECRET_ACCESS_KEY')
  USERNAME           = ENV.fetch('RDS_USERNAME')
  PASSWORD           = ENV.fetch('RDS_PASSWORD')
  DB_INSTANCE_CLASS  = ENV.fetch('RDS_DB_INSTANCE_CLASS')
  DB_ENGINE          = ENV.fetch('RDS_DB_ENGINE')
  SECURITY_GROUP_IDS = [ENV.fetch('RDS_SECURITY_GROUP_ID')].freeze
  DEFAULT_IDENTIFIER = ENV.fetch('RDS_IDENTIFIER') { 'testing' }
  RDS_KMS_KEY_ID     = ENV.fetch('RDS_KMS_KEY_ID')
  DB_NAME            = 'sql_server_openpath'.freeze
  MAX_WAIT_TIME      = 1.hour

  class << self
    attr_writer :identifier
  end

  class << self
    attr_reader :identifier
  end

  class << self
    attr_writer :timeout
  end

  def self.timeout
    @timeout || 50_000_000
  end

  def initialize
    self.identifier = Rds.identifier || DEFAULT_IDENTIFIER

    if SECRET_ACCESS_KEY.present? && SECRET_ACCESS_KEY != 'unknown'
      Aws.config.update(
        region: REGION,
        credentials: Aws::Credentials.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY),
      )
    else
      Aws.config.update(
        region: REGION,
      )
    end

    self.client = Aws::RDS::Client.new(region: REGION)
  end

  define_method(:sqlservers) { _list.select { |server| server.engine.match(/sqlserver/) } }
  define_method(:start!)     { client.start_db_instance(db_instance_identifier: identifier) }
  define_method(:stop!)      { client.stop_db_instance(db_instance_identifier: identifier) }
  define_method(:terminate!) { client.delete_db_instance(db_instance_identifier: identifier, skip_final_snapshot: true) }
  define_method(:host)       { ENV['LSA_DB_HOST'].presence || my_instance&.endpoint&.address }
  define_method(:exists?)    { !!my_instance }
  define_method(:database)   { identifier.underscore }

  def test!
    create!
    wait!
    create_database!

    # terminate!
  end

  def setup!
    create!
    wait!
    create_database!
    wait_for_database!
  end

  def create!
    return if ENV['LSA_DB_HOST'].present? || exists?

    # FIXME: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/SQLServer.Concepts.General.SSL.Using.html#SQLServer.Concepts.General.SSL.Forcing
    @response = client.create_db_instance(
      db_instance_class: DB_INSTANCE_CLASS,
      db_instance_identifier: identifier,
      allocated_storage: 20, # 20GB is minimum required
      engine: DB_ENGINE,
      master_username: USERNAME,
      master_user_password: PASSWORD,
      license_model: 'license-included',
      timezone: 'US Eastern Standard Time',
      copy_tags_to_snapshot: true,
      multi_az: false,
      engine_version: '14.00.3015.40.v1',
      tags: [
        { key: 'Rails Environment', value: Rails.env },
      ],
      storage_encrypted: true,
      kms_key_id: RDS_KMS_KEY_ID,
      backup_retention_period: 0,
      availability_zone: AVAILABILITY_ZONE,
      storage_type: 'gp2', # SSD, the cheapest choice available
      auto_minor_version_upgrade: false,
      preferred_backup_window: '06:14-06:44',
      preferred_maintenance_window: 'fri:08:13-fri:08:43',
      publicly_accessible: true,
      vpc_security_group_ids: SECURITY_GROUP_IDS,
      db_subnet_group_name: 'db_subnet_group',
      db_parameter_group_name: 'sqlserver-web-14-tls',
      option_group_name: 'default:sqlserver-web-14-00',
      port: 1433,
    )
  end

  def wait!
    Timeout.timeout(MAX_WAIT_TIME) do
      while host.blank?
        Rails.logger.debug 'no host yet'
        # puts "no host yet"
        sleep 5
      end
    end

    sleep 2

    load 'lib/rds_sql_server/sql_server_bootstrap_model.rb'

    SqlServerBootstrapModel.connection.execute(<<~SQL)
      select 1;
    SQL
  end

  def wait_for_database!
    load 'lib/rds_sql_server/sql_server_bootstrap_model.rb'

    Timeout.timeout(MAX_WAIT_TIME) do
      db_exists = false
      while db_exists == false
        db_exists = db_exists?
        Rails.logger.debug 'No DB yet' unless db_exists
        # puts "No DB yet" if db_exists == 0
        sleep 5
      end
    end
  end

  def db_exists?
    db_exists = SqlServerBootstrapModel.connection.execute(<<~SQL)
      if not exists(select * from sys.databases where name = '#{database}')
        select 0;
      else
        select 1;
    SQL
    db_exists.positive?
  end

  def create_database!
    Rails.logger.info "Creating database #{database}..."

    load 'lib/rds_sql_server/sql_server_bootstrap_model.rb'

    SqlServerBootstrapModel.connection.execute(<<~SQL)
      if not exists(select * from sys.databases where name = '#{database}')
        create database #{database}
    SQL

    Rails.logger.info "SQL Server Host detected: #{host}"
    Rails.logger.info "There are #{sqlservers.length} SQL Server database servers detected"
  end

  def my_instance
    sqlservers.find do |server|
      server.db_instance_identifier == identifier
    end
  end

  private

  define_method(:_list)       { client.describe_db_instances.db_instances }
  define_method(:_operations) { client.operation_names }
end
