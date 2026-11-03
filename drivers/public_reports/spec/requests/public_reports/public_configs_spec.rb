###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PublicReports::WarehouseReports::PublicConfigs', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      report_group: 'Reports',
      url: 'public_reports/warehouse_reports/public_configs',
      name: 'Public Report Configuration',
      description: '',
    )
  end

  before do
    collection.set_viewables(reports: [report_definition.id])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  it 're-renders the form with the error and keeps the saved value when a color is unsafe' do
    PublicReports::Setting.first_or_create.update!(summary_color: '#123456')

    post public_reports_warehouse_reports_public_configs_path, params: { config: { summary_color: 'red;}' } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include('Summary color is not a valid CSS value')
    expect(PublicReports::Setting.first.summary_color).to eq('#123456')
  end

  it 'keeps the rejected font family in the form so it can be corrected without saving it' do
    post public_reports_warehouse_reports_public_configs_path, params: { config: { font_family_0: 'Georgia;}' } }

    expect(Nokogiri::HTML(response.body).at_css('input[name="config[font_family_0]"]')['value']).to eq('Georgia;}')
    expect(PublicReports::Setting.first.font_family_0).to be_nil
  end

  it 'saves a new theme color and shows it back in the form' do
    post public_reports_warehouse_reports_public_configs_path, params: { config: { heading_color: '#abcdef' } }
    get public_reports_warehouse_reports_public_configs_path

    expect(PublicReports::Setting.first.heading_color).to eq('#abcdef')
    expect(Nokogiri::HTML(response.body).at_css('input[name="config[heading_color]"]')['value']).to eq('#abcdef')
  end

  it 'shows the theme font defaults as placeholders without filling the font inputs' do
    PublicReports::Setting.first_or_create.update!(font_url: nil, font_family_0: nil)

    get public_reports_warehouse_reports_public_configs_path

    doc = Nokogiri::HTML(response.body)
    url_input = doc.at_css('input[name="config[font_url]"]')
    family_input = doc.at_css('input[name="config[font_family_0]"]')
    expect(
      [url_input['value'].presence, url_input['placeholder'], family_input['value'].presence, family_input['placeholder']],
    ).to eq([nil, PublicReports::Setting::THEME_DEFAULTS[:font_url], nil, PublicReports::Setting::THEME_DEFAULTS[:font_body]])
  end

  it 'round-trips a per-population color, which css_values_are_safe does not validate' do
    post public_reports_warehouse_reports_public_configs_path, params: { config: { homeless_primary_color: '#112233' } }
    get public_reports_warehouse_reports_public_configs_path

    expect(Nokogiri::HTML(response.body).at_css('input[name="config[homeless_primary_color]"]')&.[]('value')).to eq('#112233')
  end

  context 'for a report-viewing user whose collection lacks the Public Configs definition' do
    let(:outsider) { create(:acl_user) }

    before do
      PublicReports::Setting.first_or_create.update!(summary_color: '#123456')
      setup_access_control(outsider, role, create(:collection))
      sign_out(user)
      sign_in(outsider)
    end

    it 'redirects away from the form that holds the S3 credentials' do
      get public_reports_warehouse_reports_public_configs_path

      expect(response).to redirect_to(outsider.my_root_path)
      expect(response.body).not_to include('config[s3_secret]')
    end

    it 'redirects away from create and leaves the setting unchanged' do
      post public_reports_warehouse_reports_public_configs_path, params: { config: { summary_color: '#abcdef' } }

      expect(response).to redirect_to(outsider.my_root_path)
      expect(PublicReports::Setting.first.summary_color).to eq('#123456')
    end
  end
end
