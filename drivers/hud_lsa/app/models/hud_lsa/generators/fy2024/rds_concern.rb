###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

module HudLsa::Generators::Fy2024::RdsConcern
  extend ActiveSupport::Concern
  include Memery
  include NotifierConfig

  def sql_server_identifier
    "#{ENV.fetch('CLIENT')&.gsub(/[^0-9a-z]/i, '')}-#{Rails.env}-LSA-#{id}".downcase
  end

  def sql_server_database
    sql_server_identifier.underscore
  end

  def setup_temporary_rds
    ::Rds.identifier = sql_server_identifier unless ::Rds.static_rds?
    ::Rds.database = sql_server_database
    ::Rds.timeout = 60_000_000
    @rds = ::Rds.new
    @rds.setup!
  end

  def create_temporary_rds
    ::Rds.identifier = sql_server_identifier unless ::Rds.static_rds?
    ::Rds.database = sql_server_database
    ::Rds.timeout = 60_000_000
    @rds = ::Rds.new
    # Sometimes a previous failed run prevents a subsequent run from completing.
    # Wait for the previous run to be fully cleaned up, but only a max of 10 minutes
    max_wait = 10 * 60
    waited = 0
    wait = 5
    begin
      while @rds&.current_state == 'deleting'
        sleep(wait)
        waited += wait
        break if waited >= max_wait
      end
    rescue Aws::RDS::Errors::DBInstanceNotFound => e
      puts "DB not found, creating. #{e.message}"
    end
    @rds.create!
  end

  def remove_temporary_rds
    return unless destroy_rds?
    return unless @rds&.exists?

    # If we didn't specify a specific host, turn off RDS
    # Otherwise, just drop the database
    if ENV['LSA_DB_HOST'].blank?
      @rds&.terminate!
    else
      begin
        SqlServerBase.connection.execute(<<~SQL)
          use master
        SQL
        SqlServerBase.connection.execute(<<~SQL)
          drop database #{@rds.database}
        SQL
      rescue Exception => e
        puts e.inspect
      end
    end
  end

  def destroy_rds?
    @destroy_rds = true if @destroy_rds.nil?
    @destroy_rds
  end

  # Use https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/User.SQLServer.Options.S3-integration.html
  # for faster data imports
  memoize def rds_s3_integration_role_arn
    GrdaWarehouse::Config.get(:rds_s3_integration_role_arn)
  end

  memoize def rds_s3_integration_enabled?
    rds_s3_integration_role_arn.present?
  end

  private def mssql_import_from_s3(file_name:, klass:)
    windows_path = s3_upload_path(file_name).gsub('/', '\\')
    # Move the S3 blob to the SQL server
    # queue_mssql_import_from_s3(file_name: file_name, klass: klass)
    wait_for_s3_file_transfer(file: windows_path, klass: klass)

    # NOTE: 0x0a is the hex representation of \n which SQL server only sometimes accepts
    sql = <<~SQL
      BULK INSERT #{klass.quoted_table_name}
      FROM '#{full_windows_path(file_name)}'
      WITH (
        FORMAT = 'CSV',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        FIRSTROW = 2
      );
    SQL
    # An alternate method, probably not needed
    # sql = <<~SQL
    #   SELECT * into #{klass.quoted_table_name}
    #   FROM OPENROWSET (
    #     BULK '#{full_windows_path}',
    #     FORMAT = 'CSV',
    #     FIRSTROW = 2
    #   ) as source;
    # SQL
    # binding.pry
    klass.connection.execute(sql)
  end

  private def queue_mssql_import_from_s3(file_name:, klass:)
    # The queue will fail until the integration completes, so try, but wait if necessary
    minutes_to_wait = 15
    wait_until = Time.current + minutes_to_wait.minutes
    @s3_feature_enabled ||= false

    # An alternate method, probably not needed
    # Enable ad-hoc distributed queries - enabled via parameter group
    # sql = <<~SQL
    #   EXEC sp_configure 'show advanced options', 1;
    #   RECONFIGURE;
    #   EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
    #   RECONFIGURE;
    # SQL
    # klass.connection.execute(sql)

    # Move the S3 blob to the SQL server
    sql = <<-SQL
      EXEC msdb.dbo.rds_download_from_s3
      @rds_file_path='#{full_windows_path(file_name)}',
      @s3_arn_of_file='arn:aws:s3:::#{s3.bucket.name}/#{s3_upload_path(file_name)}',
      @overwrite_file=1;
    SQL

    begin
      if @s3_feature_enabled
        klass.connection.execute(sql)
      else
        while !@s3_feature_enabled && Time.current < wait_until
          begin
            klass.connection.execute(sql)
            @s3_feature_enabled = true
            log_and_ping('RDS S3 Integration completed') # Probably don't need this long-term, tracking timing now
          rescue StandardError => e # Should be TinyTds::Error, but that doesn't seem to work
            raise unless e.message.include?('process of being enabled')

            log_and_ping('Waiting for RDS S3 Integration to complete') # Probably don't need this long-term, tracking timing now
            sleep(60)
            retry
          end
        end
      end
    rescue Exception => e
      # For now, rescue anything else and wait 10 minutes, unless we've already waited.  It'll either fail again, or maybe it just got confused.
      log_and_ping("Unexpected error, waiting 10 minutes, and then continuing blindly: #{e.message}")
      sleep(600) if Time.current < wait_until
    end
  end

  private def setup_instance_role
    return unless rds_s3_integration_enabled?

    @rds.client.add_role_to_db_instance(
      {
        db_instance_identifier: ::Rds.identifier,
        feature_name: 'S3_INTEGRATION',
        role_arn: rds_s3_integration_role_arn,
      },
    )
  # Don't fail if we're trying to assign the S3 integration to a database that already has it enabled
  rescue Aws::RDS::Errors::InvalidParameterValue => e
    raise e unless e.message.include?('only one ARN associated')
  # Don't fail just because the S3 integration is taking a long time to get added, we'll give it more time
  # to complete in queue_mssql_import_from_s3 just before we actually need it
  rescue ActiveRecord::StatementInvalid => e
    raise e unless e.message.include?('process of being enabled')
  end

  private def wait_for_s3_file_transfer(file:, klass:)
    minutes_to_wait = 15
    wait_until = Time.current + minutes_to_wait.minutes
    # Needs to wait until the following indicates the most-recent task_type of DOWNLOAD_FROM_S3 has a lifecycle of SUCCESS
    # We'll probably also need to handle errors (or only wait a specified amount of time)
    matched = check_for_s3_file_transfer(file: file, klass: klass)
    # Check every minute to see if the file has successfully been moved
    i = 0
    while matched['lifecycle'] != 'SUCCESS'
      # only send a note every minute, but check every 15 seconds
      log_and_ping("Waiting for S3 to RDS file transfer of: #{file}") if i % 4 == 0
      sleep(15)
      i += 1
      matched = check_for_s3_file_transfer(file: file, klass: klass)

      raise "Unable to sync #{file} to RDS, waited #{minutes_to_wait} minutes" if Time.current > wait_until
    end
  end

  private def check_for_s3_file_transfer(file:, klass:)
    sql = <<~SQL
      SELECT top 1 * FROM msdb.dbo.rds_fn_task_status(NULL,0)
      WHERE filepath like '%#{file}%'
      ORDER BY task_id desc
    SQL
    rows = klass.connection.select_all(sql)
    raise "Unable to sync #{file} to RDS" if rows.empty?

    rows.first
  end
end
