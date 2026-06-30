###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Shared by app-db (GrPaperTrail::Version) and health-db (Health::HealthVersion) paper trail rows.
# See GrdaWarehouse::Version spec for the per-era column semantics; the same invariants apply here.
# NOTE: the health `versions` table has NO `true_user_id` column, so the true-user derivation must
# not assume the column exists.
RSpec.describe GrPaperTrailVersionBehavior do
  let(:impersonator_id) { 10 } # the true user / admin
  let(:impersonated_id) { 20 } # the account being acted as

  # The app `versions` table has NO true_user_id column (it was dropped — whodunnit already carries the
  # true user). So derivation here must come entirely from whodunnit, never the user_id column whose
  # meaning flips between auth eras (true user under old Devise, acting user under JWT/new Devise).
  describe 'GrPaperTrail::Version (app db, no true_user_id column)' do
    context 'impersonation, whodunnit = "<true> as <acting>"' do
      it 'derives the acting user and the true user from whodunnit regardless of the user_id column' do
        # user_id = true user (old Devise write) and user_id = acting user (JWT/new Devise write) must
        # both resolve identically, proving the derivation does not trust the era-dependent column.
        [impersonator_id, impersonated_id].each do |user_id_value|
          version = GrPaperTrail::Version.new(
            whodunnit: "#{impersonator_id} as #{impersonated_id}",
            user_id: user_id_value,
          )
          expect(version.clean_user_id.to_i).to eq(impersonated_id)
          expect(version.clean_true_user_id.to_i).to eq(impersonator_id)
        end
      end
    end

    context 'no impersonation, whodunnit = "<user>"' do
      subject(:version) do
        GrPaperTrail::Version.new(whodunnit: impersonated_id.to_s, user_id: impersonated_id)
      end

      it 'attributes both the acting and true user to the single user' do
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
        expect(version.clean_true_user_id.to_i).to eq(impersonated_id)
      end
    end
  end

  describe 'Health::HealthVersion (health db, NO true_user_id column)' do
    context 'Devise-era impersonation' do
      subject(:version) do
        Health::HealthVersion.new(whodunnit: "#{impersonator_id} as #{impersonated_id}", user_id: impersonator_id)
      end

      it 'derives provenance without referencing the missing true_user_id column' do
        expect { version.clean_true_user_id }.not_to raise_error
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
        expect(version.clean_true_user_id.to_i).to eq(impersonator_id)
      end
    end
  end
end
