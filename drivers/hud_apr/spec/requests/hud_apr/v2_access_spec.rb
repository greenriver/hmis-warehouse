###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'APR family v2 access', type: :request do
  {
    'APR' => ['aprs', HudApr::Generators::Apr::Fy2026::Generator],
    'CAPER' => ['capers', HudApr::Generators::Caper::Fy2026::Generator],
    'CE APR' => ['ce_aprs', HudApr::Generators::CeApr::Fy2026::Generator],
    'DQ' => ['dqs', HudApr::Generators::Dq::Fy2026::Generator],
  }.each do |label, (plural, generator)|
    describe "#{label} pages" do
      it_behaves_like 'HUD report access' do
        let(:definition_url) { "hud_reports/#{plural}" }
        let(:report_name) { generator.title }
        let(:index_path) { public_send("hud_reports_#{plural}_path") }
        let(:new_path) { public_send("new_hud_reports_#{plural.singularize}_path") }
        let(:history_path) { public_send("history_hud_reports_#{plural}_path") }
        let(:report_path_for) { ->(run) { public_send("hud_reports_#{plural.singularize}_path", run) } }
      end
    end
  end
end
