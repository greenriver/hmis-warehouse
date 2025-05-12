###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
  let!(:destination_data_source) { create :destination_data_source } # allows client deduplication to run
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:user) { create(:acl_user) }
  let!(:report_group) { create :collection }
  # report viewer is a role factory. We also need can_view_projects to pass the access check in
  # GrdaWarehouse::Lookups::CocCode.viewable_by
  let!(:report_viewer) { create :report_viewer, can_view_projects: true }

  before(:each) do
    AccessGroup.maintain_system_groups
    setup_access_control(user, report_viewer, report_group)
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
