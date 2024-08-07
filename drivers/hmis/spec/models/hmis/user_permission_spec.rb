#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::User, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:alice) { create(:hmis_user, data_source: ds1, first_name: 'Alice') }
  let!(:bob) { create(:hmis_user, data_source: ds1, first_name: 'Bob') }
  let!(:charlie) { create(:hmis_user, data_source: ds1, first_name: 'Charlie') }
  let!(:diane) { create(:hmis_user, data_source: ds1, first_name: 'Diane') }

  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  describe 'User permission_for scope' do
    it 'should return correct users when permission is granted, including inherited permission' do
      create_access_control(alice, ds1, with_permission: :can_edit_enrollments)
      create_access_control(bob, o1, with_permission: :can_edit_enrollments)
      create_access_control(charlie, p1, with_permission: :can_edit_enrollments)
      create_access_control(diane, ds1, without_permission: :can_edit_enrollments)

      users = Hmis::User.can_edit_enrollments_for(p1)
      expect(users.count).to eq(3)
      expect(users).to contain_exactly(alice, bob, charlie)
    end
  end
end
