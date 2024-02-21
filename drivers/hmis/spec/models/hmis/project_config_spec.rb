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
    aec1 = Hmis::ProjectAutoEnterConfig.create!(project: p1)
    expect(aec1.id).not_to be_nil
    expect(aec1.type).to eq('Hmis::ProjectAutoEnterConfig')
  end

  it 'should not create a config if both project and organization are provided' do
    expect do
      Hmis::ProjectAutoEnterConfig.create!(project: p1, organization: o1)
    end.to raise_error(ActiveRecord::RecordInvalid, /Specify at most one of project, organization, and project type/)
  end
end
