###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::ProjectAutoExitConfig, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { create :hmis_hud_user, data_source: ds1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2, user: u1 }

  it 'should select the proper auto exit config for a project' do
    # Use the most basic config if there's no specific one
    aec1 = create(:hmis_project_auto_exit_config)
    expect(Hmis::ProjectAutoExitConfig.default_config).to eq(aec1)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p1)).to be_empty
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p1)).to eq(aec1)

    aec1.destroy!
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p1)).to be_nil

    # Project type is least specific
    aec2 = create(:hmis_project_auto_exit_config, project_type: p1.project_type)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p1)).to contain_exactly(aec2)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p1)).to eq(aec2)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p2)).to contain_exactly(aec2)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p2)).to eq(aec2)

    # Organization is more specific than project type
    aec3 = create(:hmis_project_auto_exit_config, organization_id: o1.id)
    aec4 = create(:hmis_project_auto_exit_config, organization_id: o2.id)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p1)).to contain_exactly(aec2, aec3)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p1)).to eq(aec3)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p2)).to contain_exactly(aec2, aec4)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p2)).to eq(aec4)

    # Project id is most specific
    aec5 = create(:hmis_project_auto_exit_config, project_id: p1.id)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p1)).to contain_exactly(aec2, aec3, aec5)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p1)).to eq(aec5)
    expect(Hmis::ProjectAutoExitConfig.configs_for_project(p2)).to contain_exactly(aec2, aec4)
    expect(Hmis::ProjectAutoExitConfig.config_for_project(p2)).to eq(aec4)
  end

  it 'should throw errors if the auto-exit is not configured properly' do
    expect { Hmis::ProjectAutoExitConfig.create! }.
      to raise_error(ActiveRecord::RecordInvalid, /config_options must be present/)
    expect { Hmis::ProjectAutoExitConfig.create!(config_options: 'hello world') }.
      to raise_error(ActiveRecord::RecordInvalid, /config_options must be JSON/)
    expect { Hmis::ProjectAutoExitConfig.create!(config_options: '{"foo": "bar"}') }.
      to raise_error(ActiveRecord::RecordInvalid, /config_options must contain an integer length_of_absence_days/)
    expect { Hmis::ProjectAutoExitConfig.create!(config_options: '{"length_of_absence_days": "foobar"}') }.
      to raise_error(ActiveRecord::RecordInvalid, /config_options must contain an integer length_of_absence_days/)
    expect { Hmis::ProjectAutoExitConfig.create!(config_options: '{"length_of_absence_days": 2}') }.
      to raise_error(ActiveRecord::RecordInvalid, /length_of_absence_days must greater than or equal to 30/)
  end
end
