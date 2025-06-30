###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  include_context 'ce spec helper'

  # Test primarily tests visibility of the `referral` defined in CE Spec Helper

  # Create referral in another project in the same data source
  let!(:other_project) { create :hmis_hud_project, data_source: ds1 }
  let!(:other_referral) do
    opportunity = create(:hmis_ce_opportunity, data_source: ds1, project: other_project, workflow_template: workflow_template)
    create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1)
  end

  # Grant user access to view all projects, but not view any referrals
  let!(:ds_access_control) do # overwrite the access control included with the CE spec helper
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
  end

  describe 'viewable_by scope' do
    it 'does not return any referrals when user has no permission' do
      expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to be_empty
    end

    context 'user can_view_referrals in data source' do
      let!(:acl) { create_access_control(hmis_user, ds1, with_permission: :can_view_referrals) }

      it 'includes all referrals in data source' do
        expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral, other_referral)
      end
    end

    context 'user can_view_referrals in project' do
      let!(:acl) { create_access_control(hmis_user, project, with_permission: :can_view_referrals) }

      it 'includes referral in permissioned project' do
        expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
      end
    end

    context 'user can_view_own_referrals in project' do
      let!(:acl) { create_access_control(hmis_user, project, with_permission: :can_view_own_referrals) }

      it 'does not include any referrals when user has no assigned steps' do
        expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to be_empty
      end

      context 'and user has unavailable assigned step' do
        before do
          # Contrived situation; in real workflow engine, steps become available as soon as they are created
          engine.start_workflow!(user: hmis_user)
          step = referral.steps.first
          step.update!(status: 'unavailable')
          step.assignments.create!(user: hmis_user)
        end

        it 'does not include referral' do
          expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to be_empty
        end
      end

      context 'and user has assigned step' do
        before do
          engine.start_workflow!(user: hmis_user)
          referral.participants.create!(user: hmis_user, swimlane: case_manager_swimlane)
          engine.assign_task!(referral.steps.first)
        end

        let(:step) { referral.steps.first }

        it 'includes referral when step is available' do
          expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
        end

        it 'includes referral when step is in progress' do
          engine.start_step!(step, user: hmis_user)
          expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
        end

        it 'includes referral when step is done' do
          engine.start_step!(step, user: hmis_user)
          engine.complete_step!(step, user: hmis_user, submitted_values: nil)
          expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
        end

        context 'user has multiple assigned steps' do
          before do
            referral.participants.create!(user: hmis_user, swimlane: provider_swimlane)
            engine.start_step!(step, user: hmis_user)
            engine.complete_step!(step, user: hmis_user, submitted_values: nil)
          end

          it 'includes referral and does not duplicate' do
            expect(referral.steps.count).to eq(2)
            expect(referral.steps.first.assignments.sole.user).to eq(hmis_user)
            expect(referral.steps.second.assignments.sole.user).to eq(hmis_user)
            expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
          end
        end
      end

      context 'and user has assigned step on referral in a different project' do
        # override acl to point to other_project instead
        let!(:acl) { create_access_control(hmis_user, other_project, with_permission: :can_view_own_referrals) }

        before do
          engine.start_workflow!(user: hmis_user)
          step = referral.steps.first
          referral.participants.create!(user: hmis_user, swimlane: step.swimlane)
          engine.assign_task!(step)
        end

        it 'does not include the assigned referral' do
          expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to be_empty
        end
      end
    end
  end
end
