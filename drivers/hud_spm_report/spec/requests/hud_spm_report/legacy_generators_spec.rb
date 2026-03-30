###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression spec: when legacy SPM generators were stub-ified, check that they still work
RSpec.describe 'Legacy SPM report history page', type: :request do
  let(:user) { create(:user) }
  let(:question_names) { HudSpmReport::Generators::Fy2024::Generator.questions.keys }

  ['2020', '2023', '2024'].each do |year|
    before do
      user.legacy_roles << create(:role, can_view_own_hud_reports: true)
      sign_in(user)
      create(
        :hud_reports_report_instance,
        user: user,
        report_name: "System Performance Measures - FY #{year}",
        build_for_questions: question_names,
        remaining_questions: [],
        options: { 'report_version' => "fy#{year}" },
      )
    end

    it "renders without error for a #{year} report" do
      get history_hud_reports_spms_path(filter: { report_version: "fy#{year}" })

      expect(response).to be_successful
    end
  end
end
