# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisEnrollmentPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:other_project) { create(:hmis_hud_project, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, project: project, client: client, data_source: data_source) }
  let(:policy) { user.policy_for(enrollment, policy_type: :hmis_enrollment) }

  describe '#can_edit?' do
    it 'returns true if user can edit' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_edit?).to be true
    end

    it 'returns false if user only has can_edit_enrollments (missing permission requirements)' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments])
      expect(policy.can_edit?).to be false
    end

    it 'returns false if user can view but not edit' do
      create_access_control(user, project, with_permission: [:can_view_enrollment_details, :can_view_project])
      expect(policy.can_edit?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_edit?).to be false
    end
  end

  describe '#can_delete?' do
    it 'returns true if user can delete' do
      create_access_control(user, project, with_permission: [:can_delete_enrollments, :can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_delete?).to be true
    end

    it 'returns false if user cannot delete' do
      create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_delete?).to be false
    end

    it 'returns false if user lacks can_edit_enrollments (missing permission requirements)' do
      create_access_control(user, project, with_permission: [:can_delete_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_delete?).to be false
    end

    it 'returns false if user has no permissions in this project' do
      create_access_control(user, other_project, with_permission: [:can_delete_enrollments, :can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      expect(policy.can_delete?).to be false
    end

    context 'enrollment is wip' do
      let(:enrollment) { create(:hmis_hud_wip_enrollment, project: project, client: client, data_source: data_source) }

      it 'returns true if user can edit' do
        create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        expect(policy.can_delete?).to be true
      end
    end
  end

  context 'when policy is scoped to a different data source than the enrollment' do
    let!(:ds2) { create(:hmis_data_source) }
    let!(:ds2_user) { create(:hmis_user, data_source: ds2) }
    let(:policy) { ds2_user.policy_for(enrollment, policy_type: :hmis_enrollment) } # scoped to ds2

    it 'is denied' do
      expect(policy.can_edit?).to be false
    end

    context 'and user has permission in both data sources' do
      before do
        create_access_control(ds2_user, data_source, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
        create_access_control(ds2_user, ds2, with_permission: [:can_edit_enrollments, :can_view_enrollment_details, :can_view_project])
      end

      it 'is still denied when scoped to the wrong data source' do
        expect(policy.can_edit?).to be false
      end

      it 'is allowed when scoped to the enrollment\'s data source' do
        ds2_user.hmis_data_source_id = data_source.id
        policy = ds2_user.policy_for(enrollment, policy_type: :hmis_enrollment)
        expect(policy.can_edit?).to be true
      end
    end
  end
end
