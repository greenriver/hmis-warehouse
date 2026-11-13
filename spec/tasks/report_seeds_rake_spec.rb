###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'reports:seed', type: :task do
  let(:task_name) { 'reports:seed' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'reports:seed' }
  end

  before do
    Report.delete_all
    Rake::Task[task_name].reenable
  end

  let(:pit_2018_types) { ['Reports::Pit::Fy2018::Base', 'Reports::Pit::Fy2018::ByProject'] }

  it 'does not create enabled PIT 2018 reports' do
    Rake::Task[task_name].invoke

    expect(Report.active.where(type: pit_2018_types)).not_to exist
  end

  it 'disables PIT 2018 reports that are already enabled' do
    Reports::Pit::Fy2018::Base.create!(name: 'PIT - 2018', enabled: true)
    Reports::Pit::Fy2018::ByProject.create!(name: 'PIT By Project - 2018', enabled: true)

    Rake::Task[task_name].invoke

    expect(Report.where(type: pit_2018_types).count).to eq 2
    expect(Report.active.where(type: pit_2018_types)).not_to exist
  end

  it 'does not create an enabled HIC 2019 report' do
    Rake::Task[task_name].invoke

    expect(Reports::Hic::Fy2019::Base.active).not_to exist
  end

  it 'disables a HIC 2019 report that is already enabled' do
    Reports::Hic::Fy2019::Base.create!(name: 'HIC', enabled: true)

    Rake::Task[task_name].invoke

    expect(Reports::Hic::Fy2019::Base.count).to eq 1
    expect(Reports::Hic::Fy2019::Base.active).not_to exist
  end
end
