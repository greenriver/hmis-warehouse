###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HopwaCaper::QuestionsController, type: :request do
  generator = HopwaCaper::Generators::Fy2026::Generator

  let!(:user) { create(:user) }
  let!(:report) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: generator.title,
      build_for_questions: generator.questions.keys,
    )
  end

  before do
    user.legacy_roles << create(:role, can_view_own_hud_reports: true)
    sign_in(user)
  end

  describe 'GET #show' do
    # XHR requests build pagination links off the reports "history" route, which the
    # questions controller does not define directly (regression: #6223 UrlGenerationError).
    generator.questions.keys.each do |question|
      it "renders question #{question} requested via XHR" do
        get hud_reports_hopwa_caper_question_path(hopwa_caper_id: report.id, id: question), xhr: true

        expect(response).to be_successful
      end
    end
  end
end
