###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HIC v2 access', type: :request do
  # The new page raises NameError: the form calls default_report_version, which is not a view helper.
  it_behaves_like 'HUD report access', except: [:new_page] do
    let(:definition_url) { 'hud_reports/hics' }
    let(:report_name) { HudHic::Generators::Hic::Fy2022::Generator.title }
    let(:index_path) { hud_reports_hics_path }
    let(:new_path) { new_hud_reports_hic_path }
    let(:history_path) { history_hud_reports_hics_path }
    let(:report_path_for) { ->(run) { hud_reports_hic_path(run) } }
  end
end
