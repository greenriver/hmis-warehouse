###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'eto:import:demographics_and_touch_points', type: :task do
  let(:task_name) { 'eto:import:demographics_and_touch_points' }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:credentials) do
    EccoviaData::Credential.create!(
      active: false,
      username: 'key',
      password: 'secret',
      endpoint: 'https://eccovia.example.com',
      slug: 'eccovia-task',
    )
  end
  let!(:fetch) { EccoviaData::Fetch.create!(credentials: credentials, data_source_id: data_source.id, active: false) }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'eto:import:demographics_and_touch_points' }
  end

  before do
    allow_any_instance_of(EccoviaData::Fetch).to receive(:fetch_updated)
    Rake::Task[task_name].reenable
  end

  it 'fetches every Eccovia fetch outside sandbox mode, ignoring its active flag' do
    expect_any_instance_of(EccoviaData::Fetch).to receive(:fetch_updated).once

    Rake::Task[task_name].invoke
  end

  it 'fetches nothing in sandbox mode' do
    expect_any_instance_of(EccoviaData::Fetch).not_to receive(:fetch_updated)

    with_sandbox_mode { Rake::Task[task_name].invoke }
  end
end
