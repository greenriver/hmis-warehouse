###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'MedicaidHmisInterchange::Health::Submission', type: :model do
  let!(:client) { create(:fixed_destination_client) }
  let!(:project) { create :grda_warehouse_hud_project, data_source_id: client.data_source_id }
  let!(:enrollment) { create :grda_warehouse_hud_enrollment, EntryDate: Date.current - 1.day, data_source_id: client.data_source_id, project: project }
  let!(:service_history_enrollment) do
    create(
      :grda_warehouse_service_history,
      :service_history_entry,
      client_id: client.id,
      first_date_in_program: Date.current - 1.day,
      enrollment: enrollment,
      project: project,
    )
  end

  before(:each) do
    client.build_external_health_id(identifier: 'TEST_ID')
    client.save!
  end

  it 'creates a zip file' do
    submission = MedicaidHmisInterchange::Health::Submission.new
    submission.run_and_save!('test@example.com')
    submission.remove_export_directory

    expect(submission.zip_file).to_not be_empty
    expect(submission.total_records).to eq(1)
  end

  # TODO: Tests for the homelessness flag calculations
end
