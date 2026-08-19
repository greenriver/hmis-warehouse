###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::RowProcessingNotesController, type: :request do
  let!(:data_source) { create(:data_source) }
  let!(:loader_log) { HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, summary: { 'Enrollment.csv' => {} }) }
  let!(:import_log) { create(:grda_warehouse_import_log, data_source: data_source, loader_log_id: loader_log.id) }
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:admin_role, can_view_imports: true) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    sign_in user
  end

  describe 'GET show' do
    it 'shows only the notes for the requested file' do
      matching = loader_log.row_processing_notes.create!(file_name: 'Enrollment.csv', row: 'E-1,C-BAD,ES', reason: 'no_matching_personal_id')
      loader_log.row_processing_notes.create!(file_name: 'Exit.csv', row: 'E-1,2020-01-01', reason: 'orphaned_child_record')

      get hmis_csv_importer_row_processing_note_path(loader_log, file: 'Enrollment.csv')

      expect(response.body).to include(matching.reason)
      expect(response.body).not_to include('orphaned_child_record')
    end
  end
end
