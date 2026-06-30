###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Provenance derivation for warehouse-db paper trail rows.
#
# Two auth eras write the columns with *opposite* meaning, while `whodunnit` is written identically
# by ApplicationController#user_for_paper_trail in both eras:
#   * Devise:  user_id = warden.user (the TRUE/impersonator), true_user_id = NULL
#   * JWT:     user_id = current_user (the IMPERSONATED user), true_user_id = the true user
# `clean_user_id` (the acting/impersonated user) and `clean_true_user_id` (the human behind it) must
# resolve correctly regardless of era.
RSpec.describe GrdaWarehouse::Version do
  let(:impersonator_id) { 10 } # the true user / admin
  let(:impersonated_id) { 20 } # the account being acted as

  describe 'provenance derivation' do
    context 'Devise-era impersonation (user_id = true user, true_user_id NULL)' do
      subject(:version) do
        described_class.new(
          whodunnit: "#{impersonator_id} as #{impersonated_id}",
          user_id: impersonator_id,
          true_user_id: nil,
        )
      end

      it 'attributes the action to the impersonated (acting) user' do
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
      end

      it 'attributes the true user to the impersonator' do
        expect(version.clean_true_user_id.to_i).to eq(impersonator_id)
      end
    end

    context 'Devise-era, no impersonation (user_id = acting user, true_user_id NULL)' do
      subject(:version) do
        described_class.new(
          whodunnit: impersonated_id.to_s,
          user_id: impersonated_id,
          true_user_id: nil,
        )
      end

      it 'attributes the action to the acting user' do
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
      end

      it 'reports no distinct true user' do
        expect(version.clean_true_user_id).to be_blank
      end
    end

    context 'JWT-era impersonation (user_id = impersonated user, true_user_id = true user)' do
      subject(:version) do
        described_class.new(
          whodunnit: "#{impersonator_id} as #{impersonated_id}",
          user_id: impersonated_id,
          true_user_id: impersonator_id,
        )
      end

      it 'attributes the action to the impersonated (acting) user' do
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
      end

      it 'attributes the true user to the impersonator' do
        expect(version.clean_true_user_id.to_i).to eq(impersonator_id)
      end
    end

    context 'JWT-era, no impersonation (user_id == true_user_id)' do
      subject(:version) do
        described_class.new(
          whodunnit: impersonated_id.to_s,
          user_id: impersonated_id,
          true_user_id: impersonated_id,
        )
      end

      it 'attributes the action to the acting user' do
        expect(version.clean_user_id.to_i).to eq(impersonated_id)
      end

      it 'reports no distinct true user' do
        expect(version.clean_true_user_id).to be_blank
      end
    end
  end
end
