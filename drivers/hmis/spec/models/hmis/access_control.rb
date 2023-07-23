###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::AccessControl, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:o2) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p3) { create :hmis_hud_project, data_source: ds1, organization: o2 }
  let(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  describe 'entity ownership tests' do
    it 'should apply correctly when attached directly to a project' do
      create_access_control(hmis_user, p1)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(false)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(false)
    end

    it 'should apply correctly when attached to a project\'s organization' do
      create_access_control(hmis_user, o1)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(false)
    end

    it 'should apply correctly when attached to a data source' do
      create_access_control(hmis_user, ds1)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p3)).to eq(true)
    end
  end

  describe 'specific permissions tets' do
    it 'should have correct permissions based on the role' do
      create_access_control(hmis_user, p1, without_permission: :can_view_full_ssn)
      expect(hmis_user.can_view_clients_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(false)
    end

    it 'should handle roles attached to other related entities correctly (broader perm at org-level is applied)' do
      # p1 is in o1
      create_access_control(hmis_user, p1, without_permission: :can_view_full_ssn)
      create_access_control(hmis_user, o1)

      expect(hmis_user.can_view_full_ssn_for?(o1)).to eq(true)
      expect(hmis_user.can_view_clients_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true) # highest perm is applied
      expect(hmis_user.can_view_clients_for?(p2)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(true)
    end

    it 'should handle roles attached to other related entities correctly (broader perm at project-level is applied)' do
      # p1 is in o1
      create_access_control(hmis_user, p1)
      create_access_control(hmis_user, o1, without_permission: :can_view_full_ssn)

      expect(hmis_user.can_view_full_ssn_for?(o1)).to eq(false)
      expect(hmis_user.can_view_full_ssn_for?(p1)).to eq(true)
      expect(hmis_user.can_view_full_ssn_for?(p2)).to eq(false)
    end
  end
end
