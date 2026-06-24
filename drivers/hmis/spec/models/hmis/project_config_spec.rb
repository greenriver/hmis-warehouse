###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ProjectConfig, type: :model do
  let!(:ds1) { create :hmis_primary_data_source }
  let!(:u1) { create :hmis_hud_user, data_source: ds1 }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }

  it 'should create an auto entry config' do
    auto_enter_config = Hmis::ProjectAutoEnterConfig.create!(project: p1, data_source: ds1)
    expect(auto_enter_config.id).not_to be_nil
    expect(auto_enter_config.type).to eq('Hmis::ProjectAutoEnterConfig')
  end

  it 'should not create a config if both project and organization are provided' do
    expect do
      Hmis::ProjectAutoEnterConfig.create!(project: p1, organization: o1, data_source: ds1)
    end.to raise_error(ActiveRecord::RecordInvalid, /Specify exactly one of project, organization, and project type/)
  end

  it 'should not create a config if none of project, organization, or project type are provided' do
    expect do
      Hmis::ProjectAutoEnterConfig.create!(data_source: ds1)
    end.to raise_error(ActiveRecord::RecordInvalid, /Specify exactly one of project, organization, and project type/)
  end

  it 'should return nil if no auto-enter config exists, even if auto-exit configs exist' do
    config = Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(p1)
    expect(config).to be_nil
    Hmis::ProjectAutoExitConfig.create!(project: p1, options: { 'length_of_absence_days': 90 }, data_source: ds1)
    config = Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(p1)
    expect(config).to be_nil
  end

  it 'should return nil if an auto-enter config exists, but is not enabled' do
    auto_enter_config = Hmis::ProjectAutoEnterConfig.create!(project: p1, data_source: ds1)
    config = Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(p1)
    expect(config).not_to be_nil
    auto_enter_config.enabled = false
    auto_enter_config.save!
    config = Hmis::ProjectAutoEnterConfig.detect_best_config_for_project(p1)
    expect(config).to be_nil
  end

  it 'does not allow config type to change once set' do
    config = create(:hmis_project_auto_enter_config, project: p1, data_source: ds1)
    config.type = Hmis::ProjectConfig::AUTO_EXIT_CONFIG

    expect(config).not_to be_valid
    expect(config.errors[:config_type]).to include('cannot be changed once set')
  end

  describe '.viewable_by' do
    let!(:ds1) { create(:hmis_data_source) }
    let!(:ds2) { create(:hmis_data_source) }
    let!(:o1) { create(:hmis_hud_organization, data_source: ds1) }
    let!(:p1) { create(:hmis_hud_project, data_source: ds1, organization: o1) }
    let!(:config_p1) { create(:hmis_project_auto_enter_config, project: p1, data_source: ds1) }
    let!(:config_ds2_project_type) do
      create(:hmis_project_auto_enter_config, data_source: ds2, project_type: 0)
    end

    let(:authorized_user) do
      u = create(:hmis_user, data_source: ds1)
      create_access_control(u, ds1)
      u
    end

    let(:user_without_perm) do
      u = create(:hmis_user, data_source: ds1)
      create_access_control(u, ds1, without_permission: [:can_configure_data_collection])
      u
    end

    it 'returns only configs in the user data source when the user has can_configure_data_collection' do
      expect(described_class.viewable_by(authorized_user)).to contain_exactly(config_p1)
    end

    it 'returns none when the user lacks can_configure_data_collection in the data source' do
      expect(described_class.viewable_by(user_without_perm)).to be_empty
    end
  end
end
