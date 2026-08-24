###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::RowProcessingNote, type: :model do
  it 'belongs to a loader log' do
    loader_log = HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: create(:grda_warehouse_data_source).id, status: :started, summary: {})
    note = loader_log.row_processing_notes.create!(file_name: 'Enrollment.csv', row: 'E-1,C-1,ES', reason: 'no_matching_personal_id')

    expect(loader_log.reload.row_processing_notes).to eq([note])
  end
end
