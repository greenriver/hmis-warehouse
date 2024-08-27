require 'rails_helper'
require_relative 'hopwa_caper_helpers'

RSpec.shared_context 'HOPWA CAPER shared context' do
  include HopwaCaperHelpers

  let(:generator) { HopwaCaper::Generators::Fy2024::Generator }
  let(:coc_code) { 'XX-500' }
  let(:today) { Date.current }
  let(:report_start_date) { today - 1.year }
  let(:report_end_date) { today }
  let(:data_source) { create :source_data_source }
  let(:user) { create(:user) }
  before(:each) do
    AccessGroup.maintain_system_groups
    AccessGroup.where(name: 'All Data Sources').first.add(user)
  end

  let(:hiv_positive) do
    HudUtility2024.disability_types.invert.fetch('HIV/AIDS')
  end

  let(:hopwa_financial_assistance) do
    HudUtility2024.record_types.invert.fetch('HOPWA Financial Assistance')
  end

  let(:rental_assistance) do
    HudUtility2024.hopwa_financial_assistance_options.invert.fetch('Rental assistance')
  end
end
