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

  let!(:other_referral) { create(:hmis_ce_referral) }

  let!(:ds_access_control) do # overwrite the access control included with the CE spec helper
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
  end

  describe 'viewable_by scope' do
    it 'does not return any referrals when user has no permission' do
      expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to be_empty
    end

    context 'user can_view_referrals' do
      let!(:acl) { create_access_control(hmis_user, ds1, with_permission: :can_view_referrals) }

      it 'includes referral in permissioned project' do
        expect(Hmis::Ce::Referral.viewable_by(hmis_user)).to contain_exactly(referral)
      end
    end

    context 'user can_view_own_referrals' do
      let!(:acl) { create_access_control(hmis_user, ds1, with_permission: :can_view_own_referrals) }

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
          step = referral.steps.first
          referral.participants.create!(user: hmis_user, swimlane: step.swimlane)
          engine.assign_task!(step)
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
    end
  end
end
