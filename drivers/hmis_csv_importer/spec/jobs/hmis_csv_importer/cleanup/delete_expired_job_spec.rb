###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'shared'

RSpec.describe HmisCsvImporter::Cleanup::DeleteExpiredJob, type: :model do
  include_context 'HmisCsvImporter cleanup context'

  def loader_records
    HmisCsvTwentyTwentyFour::Loader::Organization.with_deleted
  end

  def importer_records
    HmisCsvTwentyTwentyFour::Importer::Organization.with_deleted
  end

  describe 'with some expired import records' do
    before(:each) do
      import_csv_records(run_at: now - 1.day)
      loader_records.update_all(expired: true)
      importer_records.update_all(expired: true)
      import_csv_records(run_at: now)
    end

    it 'deletes deleted' do
      expect do
        HmisCsvImporter::Cleanup::DeleteExpiredJob.new.perform
      end.to change { loader_records.where(expired: true).count }.from(1).to(0).
        and change { importer_records.where(expired: true).count }.from(1).to(0).
        and not_change { loader_records.where(expired: false).count }.
        and(not_change { importer_records.where(expired: false).count })
    end
  end
end
