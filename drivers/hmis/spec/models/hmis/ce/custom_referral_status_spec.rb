# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Ce::CustomReferralStatus, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    puts "PaperTrail enabled: #{PaperTrail.enabled?} - build_record"
    -> { create(:hmis_ce_custom_referral_status, data_source: ds1) }
  end

  let(:update_attributes_for_versioning) do
    puts "PaperTrail enabled: #{PaperTrail.enabled?} - update_attributes_for_versioning"
    ->(record) { record.update!(name: "Updated #{record.name}") }
  end

  describe 'paranoia' do
    puts "PaperTrail enabled: #{PaperTrail.enabled?}"
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
