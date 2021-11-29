# https://docs.aws.amazon.com/sdkforruby/api/index.html
# https://docs.aws.amazon.com/sdkforruby/api/Aws/RDS.html

require 'aws-sdk-glacier'

class Rds
  attr_accessor :client

  REGION             ||= 'us-east-1'.freeze
  AVAILABILITY_ZONE  ||= 'us-east-1a'.freeze
  ACCESS_KEY_ID      ||= ENV.fetch('RDS_AWS_ACCESS_KEY_ID')
  SECRET_ACCESS_KEY  ||= ENV.fetch('RDS_AWS_SECRET_ACCESS_KEY')
  USERNAME           ||= ENV.fetch('RDS_USERNAME')
  PASSWORD           ||= ENV.fetch('RDS_PASSWORD')
  DB_INSTANCE_CLASS  ||= ENV.fetch('RDS_DB_INSTANCE_CLASS')
  DB_ENGINE          ||= ENV.fetch('RDS_DB_ENGINE')
  SECURITY_GROUP_IDS ||= [ENV.fetch('RDS_SECURITY_GROUP_ID')].freeze
  DEFAULT_IDENTIFIER ||= ENV.fetch('RDS_IDENTIFIER') { 'testing' }
  RDS_KMS_KEY_ID     ||= ENV.fetch('RDS_KMS_KEY_ID')
  DB_SUBNET_GROUP    ||= ENV.fetch('DB_SUBNET_GROUP') { 'without us-east-1e' }
  MAX_WAIT_TIME      ||= 1.hour

  NEVER_STARTING_STATUSES ||= [
    'deleting',
    'failed',
    'stopped',
    'stopping',
    'storage-full',
  ].freeze

  class << self
    attr_writer :timeout
  end

  def self.timeout
    @timeout || 50_000_000
  end

  def initialize
    # if environment is set up correctly, this can be
    # self.client = Aws::RDS::Client.new
    if SECRET_ACCESS_KEY.present? && SECRET_ACCESS_KEY != 'unknown'
      self.client = Aws::RDS::Client.new({
                                           region: REGION,
                                           access_key_id: ACCESS_KEY_ID,
                                           secret_access_key: SECRET_ACCESS_KEY,
                                         })
    else
      self.client = Aws::RDS::Client.new({
                                           region: REGION,
                                         })
    end
  end

  define_method(:sqlservers) { _list.select { |server| server.engine.match(/sqlserver/) } }

  def start!
    status = instance_data.db_instance_status

    if status.in?(['available', 'starting'])
      Rails.logger.info "Not starting #{identifier}. It's #{status}"
    elsif status == 'stopped'
      Rails.logger.info "Starting #{identifier}."
      client.start_db_instance(db_instance_identifier: identifier)
      sleep 10
    else
      raise "Couldn't start since #{identifier} has a status of #{status}"
    end
  end

  def stop!
    status = instance_data.db_instance_status

    if status.in?(['stopped', 'stopping'])
      Rails.logger.info "Not stopping #{identifier}. It's already #{status}"
    elsif status == 'available'
      Rails.logger.info "Stopping #{identifier}."
      client.stop_db_instance(db_instance_identifier: identifier)
      sleep 10
    else
      raise "Couldn't stop since #{identifier} has a status of #{status}"
    end
  end

  define_method(:terminate!) { client.delete_db_instance(db_instance_identifier: identifier, skip_final_snapshot: true) }
  define_method(:host)       { ENV['LSA_DB_HOST'].presence || my_instance&.endpoint&.address }
  define_method(:exists?)    { !!my_instance }

  delegate :static_rds?, :database, :database=, :identifier, :identifier=,
           to: Rds

  def self.static_rds?
    ENV['RDS_IDENTIFIER'].present?
  end

  def self.database
    if @database.present?
      @database
    elsif !static_rds?
      identifier.underscore
    else
      DEFAULT_IDENTIFIER.underscore
    end
  end

  # rubocop:disable Style/TrivialAccessors
  def self.database=(database)
    @database = database
  end
  # rubocop:enable Style/TrivialAccessors

  def self.identifier
    if static_rds?
      ENV['RDS_IDENTIFIER']
    elsif @identifier.present?
      @identifier
    else
      DEFAULT_IDENTIFIER
    end
  end

  def self.identifier=(ident)
    raise 'Cannot set identifier' if static_rds?

    @identifier = ident
  end

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
    GrdaWarehouseBase.connection.reconnect!
    ApplicationRecord.connection.reconnect!
    ReportingBase.connection.reconnect!
  end

  def create!
    if ENV['LSA_DB_HOST'].present? || exists?
      # This should be fine if it's already running
      start!
      return
    end

    # FIXME: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/SQLServer.Concepts.General.SSL.Using.html#SQLServer.Concepts.General.SSL.Forcing
    @response = client.create_db_instance(
      db_instance_class: DB_INSTANCE_CLASS,
      db_instance_identifier: identifier,
      allocated_storage: 100, # 20GB is minimum required, 100 so we don't run out of space
      engine: DB_ENGINE,
      master_username: USERNAME,
      master_user_password: PASSWORD,
      license_model: 'license-included',
      timezone: 'US Eastern Standard Time',
      copy_tags_to_snapshot: true,
      multi_az: false,
      engine_version: '14.00.3381.3.v1',
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
      db_subnet_group_name: DB_SUBNET_GROUP,
      db_parameter_group_name: 'sqlserver-web-14-tls',
      option_group_name: 'default:sqlserver-web-14-00',
      port: 1433,
    )
  end

  def wait!
    status = instance_data.db_instance_status

    # rubocop:disable Style/IfUnlessModifier
    if status.in?(NEVER_STARTING_STATUSES)
      raise "Can't wait. It doesn't look like the instance will ever start. It's #{status}"
    end

    # rubocop:enable Style/IfUnlessModifier

    Timeout.timeout(MAX_WAIT_TIME) do
      until host.present? && instance_data.db_instance_status == 'available'
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

    # If we had a previous LSA, this class will still have connection
    # information for that other database.
    load 'lib/rds_sql_server/sql_server_base.rb'

    Timeout.timeout(MAX_WAIT_TIME) do
      db_exists = false
      while db_exists == false
        db_exists = db_exists?
        Rails.logger.debug 'No DB yet' unless db_exists
        # puts "No DB yet" if db_exists == 0
        sleep 5
      end
      can_create_table = false
      while can_create_table == false
        begin
          load 'lib/rds_sql_server/lsa/fy2021/lsa_sql_server.rb'
          ::LsaSqlServer::DbUp.hmis_table_create!(version: '2022')
          ::LsaSqlServer::DbUp.create!(status: 'up')
          can_create_table = true
        rescue Exception => e
          Rails.logger.error e.message
          sleep 60
        end
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

  def current_state
    instance_data.db_instance_status
  end

  private

  def instance_data
    resp = client.describe_db_instances(db_instance_identifier: identifier)

    raise "Couldn't stop since we couldn't find an instance and figure out its state" if resp.db_instances.length != 1

    resp.db_instances.first
  end

  define_method(:_list)       { client.describe_db_instances.db_instances }
  define_method(:_operations) { client.operation_names }
end
