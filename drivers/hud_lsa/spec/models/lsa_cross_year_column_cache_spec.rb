###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Both fiscal-year generators `load` files that reopen the same LsaSqlServer
# classes, and a delayed_job worker can run one year after the other. These
# examples need a real SQL Server: locally, start it with
# `docker compose --profile lsa up -d mssql` and pass the LSA_DB_HOST/RDS_* env
# vars to the spec service. They are skipped when LSA_DB_HOST is unset.
RSpec.describe 'LSA generators run back to back in one process', type: :model do
  # The generators reconnect the Postgres connections mid-run, which would
  # discard a wrapping test transaction. Nothing here writes to Postgres.
  self.use_transactional_tests = false

  around do |example|
    skip 'requires SQL Server; set LSA_DB_HOST' if ENV['LSA_DB_HOST'].blank?

    no_lsa_rds = ENV.delete('NO_LSA_RDS')
    load 'lib/rds_sql_server/rds.rb'
    @databases = []
    @user = create(:acl_user)
    begin
      example.run
    ensure
      drop_databases(@databases)
      @user.destroy
      ENV['NO_LSA_RDS'] = no_lsa_rds if no_lsa_rds
    end
  end

  def prepared_generator(klass)
    generator = klass.new(
      id: SecureRandom.random_number(1_000_000_000),
      user_id: @user.id,
      options: { start: '2025-10-01', end: '2026-09-30', coc_code: 'XX-501', lsa_scope: 1 },
    )
    # The filter drops CoC codes the user can't access; Lsa#calculate makes the
    # same override in test mode.
    generator.filter.coc_code = 'XX-501'
    @databases << generator.sql_server_database
    generator.setup_temporary_rds
    generator.setup_lsa_table_structure
    generator
  end

  def drop_databases(databases)
    load 'lib/rds_sql_server/sql_server_bootstrap_model.rb'
    databases.each do |database|
      SqlServerBootstrapModel.connection.execute(<<~SQL)
        if exists(select * from sys.databases where name = '#{database}')
        begin
          alter database #{database} set single_user with rollback immediate;
          drop database #{database};
        end
      SQL
    end
  end

  it 'creates the FY2026 LSAReport row after an FY2027 run cached the FY2027 columns' do
    prepared_generator(HudLsa::Generators::Fy2027::Lsa).setup_lsa_report
    expect(LsaSqlServer::LSAReport.column_names).to include('SSN4Digit')

    prepared_generator(HudLsa::Generators::Fy2026::Lsa).setup_lsa_report

    expect(LsaSqlServer::LSAReport.pluck(:ReportCoC)).to eq(['XX-501'])
    expect(LsaSqlServer::LSAReport.column_names).not_to include('SSN4Digit')
  end
end
