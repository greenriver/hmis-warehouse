###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data

    @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2026.projects.map(&:id),
      period_type: 3,
      directive: 3,
      hash_status: 1,
      user_id: ExportHelper2026.user.id,
    )
    ExportHelper2026.instance_variable_set(:@exporter, @exporter)
    @hidden_destination, @open_destination = @exporter.client_scope.order(:id).first(2)
    GrdaWarehouse::ClientRetentionMark.delete_all
    GrdaWarehouse::ClientRetentionMark.create!(
      client_id: @hidden_destination.source_clients.first.id,
      marked_on: Date.current,
      last_activity_on: 10.years.ago.to_date,
      retention_years: 7,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    GrdaWarehouse::ClientRetentionMark.delete_all
    ExportHelper2026.cleanup
  end

  def client_rows
    CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.client_class), headers: true).index_by { |row| row['PersonalID'].to_i }
  end

  it 'redacts name and SSN in Client.csv for the destination of a retention-marked source' do
    row = client_rows.fetch(@hidden_destination.id)

    expect(row.to_h).to include('FirstName' => GrdaWarehouse::PiiProvider::REDACTED, 'LastName' => GrdaWarehouse::PiiProvider::REDACTED, 'SSN' => '', 'SSNDataQuality' => '99')
  end

  it 'leaves an unmarked client in the same export untouched' do
    row = client_rows.fetch(@open_destination.id)

    expect(row.to_h).to include('FirstName' => @open_destination.FirstName.first(50), 'SSN' => @open_destination.SSN)
  end
end
