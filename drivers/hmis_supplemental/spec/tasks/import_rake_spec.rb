###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'driver:hmis_supplemental:import', type: :task do
  let(:task_name) { 'driver:hmis_supplemental:import' }
  let!(:data_set) { create(:hmis_supplemental_data_set, sync_enabled: true) }
  let(:job) { instance_double(HmisSupplemental::ImportJob, perform: nil) }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'driver:hmis_supplemental:import' }
  end

  before do
    create(:hmis_supplemental_data_set, sync_enabled: false)
    allow(HmisSupplemental::ImportJob).to receive(:new).and_return(job)
    Rake::Task[task_name].reenable
  end

  it 'imports each sync-enabled data set outside sandbox mode' do
    Rake::Task[task_name].invoke

    expect(job).to have_received(:perform).with(data_set_id: data_set.id).once
  end

  it 'imports nothing in sandbox mode' do
    with_sandbox_mode { Rake::Task[task_name].invoke }

    expect(job).not_to have_received(:perform)
  end
end
