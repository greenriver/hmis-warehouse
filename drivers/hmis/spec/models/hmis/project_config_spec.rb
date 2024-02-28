###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::ProjectConfig, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:u1) { create :hmis_hud_user, data_source: ds1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }

  it 'should create an auto entry config' do
    auto_enter_config = Hmis::ProjectAutoEnterConfig.create!(project: p1)
    expect(auto_enter_config.id).not_to be_nil
    expect(auto_enter_config.type).to eq('Hmis::ProjectAutoEnterConfig')
  end

  it 'should not create a config if both project and organization are provided' do
    expect do
      Hmis::ProjectAutoEnterConfig.create!(project: p1, organization: o1)
    end.to raise_error(ActiveRecord::RecordInvalid, /Specify exactly one of project, organization, and project type/)
  end

  it 'should not create a config if none of project, organization, or project type are provided' do
    expect do
      Hmis::ProjectAutoEnterConfig.create!
    end.to raise_error(ActiveRecord::RecordInvalid, /Specify exactly one of project, organization, and project type/)
  end

  it 'should return nil if no auto-enter config exists, even if auto-exit configs exist' do
    config = Hmis::ProjectAutoEnterConfig.config_for_project(p1)
    expect(config).to be_nil
    Hmis::ProjectAutoExitConfig.create!(project: p1, options: { 'length_of_absence_days': 90 })
    config = Hmis::ProjectAutoEnterConfig.config_for_project(p1)
    expect(config).to be_nil
  end

  it 'should return nil if an auto-enter config exists, but is not enabled' do
    auto_enter_config = Hmis::ProjectAutoEnterConfig.create!(project: p1)
    config = Hmis::ProjectAutoEnterConfig.config_for_project(p1)
    expect(config).not_to be_nil
    auto_enter_config.enabled = false
    auto_enter_config.save!
    config = Hmis::ProjectAutoEnterConfig.config_for_project(p1)
    expect(config).to be_nil
  end
end
