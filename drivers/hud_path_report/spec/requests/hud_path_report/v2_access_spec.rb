###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PATH v2 access', type: :request do
  it_behaves_like 'HUD report access' do
    let(:definition_url) { 'hud_reports/paths' }
    let(:report_name) { HudPathReport::Generators::Fy2026::Generator.title }
    let(:index_path) { hud_reports_paths_path }
    let(:new_path) { new_hud_reports_path_path }
    let(:history_path) { history_hud_reports_paths_path }
    let(:report_path_for) { ->(run) { hud_reports_path_path(run) } }
  end
end
