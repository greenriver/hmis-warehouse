#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::AccessGroup, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:ds2) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:o2) { create :hmis_hud_organization, data_source: ds2 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2 }

  describe 'contains_with_inherited scope' do
    it 'should return correct access groups when permission is granted on whole data source' do
      create_access_control(hmis_user, ds1)

      expect(Hmis::AccessGroup.contains_with_inherited(ds1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(ds2).count).to eq(0)

      expect(Hmis::AccessGroup.contains_with_inherited(o1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(o2).count).to eq(0)

      expect(Hmis::AccessGroup.contains_with_inherited(p1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(p2).count).to eq(0)
    end

    it 'should return access groups when permission is granted on organization' do
      create_access_control(hmis_user, o1)
      expect(Hmis::AccessGroup.contains_with_inherited(ds2).count).to eq(0)
      expect(Hmis::AccessGroup.contains_with_inherited(o1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(p1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(p2).count).to eq(0)
    end

    it 'should return access groups when permission is granted on project' do
      create_access_control(hmis_user, p1)
      expect(Hmis::AccessGroup.contains_with_inherited(p1).count).to eq(1)
      expect(Hmis::AccessGroup.contains_with_inherited(p2).count).to eq(0)
    end
  end
end
