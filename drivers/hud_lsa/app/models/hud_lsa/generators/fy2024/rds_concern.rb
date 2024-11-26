###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2024::RdsConcern
  extend ActiveSupport::Concern

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

  memoize def rds_s3_integration_role_arn
    GrdaWarehouse::Config.get(:rds_s3_integration_role_arn)
  end

  memoize def rds_s3_integration_enabled?
    rds_s3_integration_role_arn.present?
  end

  private def mssql_import_from_s3(s3, path:, klass:)
    windows_path = path.gsub('/', '\\')
    # Move the S3 blob to the SQL server
    full_windows_path = "D:\\S3\\#{s3.bucket.name}\\#{windows_path}"
    sql = <<-SQL
      EXEC msdb.dbo.rds_download_from_s3
      @rds_file_path='#{full_windows_path}',
      @s3_arn_of_file='arn:aws:s3:::#{s3.bucket.name}/#{path}',
      @overwrite_file=1;
    SQL

    minutes_to_wait = 15
    wait_until = Time.current + minutes_to_wait.minutes
    @s3_feature_enabled ||= false
    if @s3_feature_enabled
      klass.connection.execute(sql)
    else
      while !@s3_feature_enabled && Time.current < wait_until
        begin
          klass.connection.execute(sql)
          @s3_feature_enabled = true
        rescue TinyTds::Error # FIXME: this needs to be more specific
          sleep(60)
        end
      end
    end

    wait_for_s3_file_transfer(file: windows_path, klass: klass)

    # NOTE: 0x0a is the hex representation of \n which SQL server only sometimes accepts
    sql = <<~SQL
      BULK INSERT #{klass.quoted_table_name}
      FROM '#{full_windows_path}'
      WITH (
        FORMAT = 'CSV',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        FIRSTROW = 2
      );
    SQL
    klass.connection.execute(sql)
  end

  private def setup_instance_role
    @rds.client.add_role_to_db_instance(
      {
        db_instance_identifier: ::Rds.identifier,
        feature_name: 'S3_INTEGRATION',
        role_arn: rds_s3_integration_role_arn,
      },
    )
  rescue Aws::RDS::Errors::InvalidParameterValue => e
    raise e unless e.full_message.include?('only one ARN associated')
  end

  private def wait_for_s3_file_transfer(file:, klass:)
    minutes_to_wait = 15
    wait_until = Time.current + minutes_to_wait.minutes
    # Needs to wait until the following indicates the most-recent task_type of DOWNLOAD_FROM_S3 has a lifecycle of SUCCESS
    # We'll probably also need to handle errors (or only wait a specified amount of time)
    matched = check_for_s3_file_transfer(file: file, klass: klass)
    # Check every minute to see if the file has successfully been moved
    while matched['lifecycle'] != 'SUCCESS'
      sleep(60)
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
