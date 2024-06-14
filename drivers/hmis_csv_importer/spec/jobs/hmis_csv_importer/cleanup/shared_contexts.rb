###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.shared_context 'HmisCsvImporter cleanup context' do
  let(:now) { DateTime.current }

  let(:data_source) do
    GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
  end

  def import_records(run_at:)
    Timecop.freeze(run_at) do
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/allowed_projects',
        version: 'AutoMigrate',
        data_source: data_source,
        run_jobs: false,
        allowed_projects: true,
      )
    end
  end
end
