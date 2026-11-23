###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LSA new page CoC default', type: :request do
  let(:lsa_generator) { HudLsa::Generators::Fy2027::Lsa }
  let(:user) { create(:acl_user) }
  let(:options_without_coc) { { 'start' => '2025-10-01', 'end' => '2026-09-30', 'project_ids' => [] } }

  before do
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:site_coc_codes).and_return('XX-501, XX-502')
    grant_hud_report(user, 'hud_reports/lsas')
    sign_in(user)
  end

  it "uses the site's first CoC code when the user's last LSA run saved none" do
    create(:hud_reports_report_instance, type: lsa_generator.name, user: user, report_name: lsa_generator.title, options: options_without_coc)

    get new_hud_reports_lsa_path

    expect(response).to have_http_status(:ok)
    expect(assigns(:filter).coc_code).to eq('XX-501')
  end

  it "uses the site's first CoC code when the user's last HIC run saved none" do
    hic_options = options_without_coc.merge('lsa_scope' => HudLsa::Fy2027::Report.available_lsa_scopes['HIC'])
    create(:hud_reports_report_instance, type: lsa_generator.name, user: user, report_name: lsa_generator.title, options: hic_options)

    get new_hud_reports_lsa_hic_path

    expect(response).to have_http_status(:ok)
    expect(assigns(:filter).coc_code).to eq('XX-501')
  end
end
