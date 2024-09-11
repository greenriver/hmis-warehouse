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
end
