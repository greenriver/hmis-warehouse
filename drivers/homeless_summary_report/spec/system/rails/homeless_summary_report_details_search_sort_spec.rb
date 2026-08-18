###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Homeless Summary Report details search and sort', type: :rails_system do
  include_context 'RailsSystemHelper'

  let(:data_source) { create(:data_source_fixed_id) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }
  let!(:destination_data_source) { create(:destination_data_source) }

  # Three clients with distinct, alphabetically distinguishable names and distinct cell
  # values, so both search (substring match) and sort (order change) are unambiguous.
  let(:clients) do
    [
      { first_name: 'Alix', last_name: 'Anderson', value: 5 },
      { first_name: 'Blair', last_name: 'Baker', value: 15 },
      { first_name: 'Casey', last_name: 'Clark', value: 25 },
    ].map do |attrs|
      source_client = create(:hud_client, data_source: data_source, first_name: attrs[:first_name], last_name: attrs[:last_name])
      create(:hud_enrollment, client: source_client, project: project)
      destination_client = create(:hud_client, data_source_id: destination_data_source.id)
      create(:warehouse_client, source_id: source_client.id, destination_id: destination_client.id)
      { destination_client: destination_client, **attrs }
    end
  end

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: HomelessSummaryReport::Report.url,
      name: 'System Performance Measures by Sub-Population',
      report_group: 'Reports',
      description: 'A summary of SPMs 1, 2, and 7 with sub-population and demographic details',
    )
  end
  let(:access_group) { create(:access_group) }
  let(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_clients: true,
      can_view_client_name: true,
    )
  end
  let(:user) do
    user = create(:user)
    role.add(user)
    access_group.add(user)
    access_group.add_viewable(report_definition)
    access_group.add_viewable(project)
    user
  end

  let(:report) { HomelessSummaryReport::Report.create!(user_id: user.id) }

  before do
    clients.each do |attrs|
      report.clients.create!(
        client_id: attrs[:destination_client].id,
        first_name: attrs[:first_name],
        last_name: attrs[:last_name],
        spm_all_persons__all: 1,
        spm_m1b_es_sh_ph_days: attrs[:value],
      )
    end

    sign_in_user(user)
  end

  describe 'details table', js: true do
    it 'shows a download button, search box, and one row per client' do
      visit details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all')

      expect(page).to have_link('Download Excel')
      expect(page).to have_css('#table_search')
      clients.each { |attrs| expect(page).to have_content(attrs[:first_name]) }
    end

    it 'filters visible rows when searching by name' do
      visit details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all')

      fill_in 'table_search', with: 'Blair'

      expect(page).to have_content('Blair')
      expect(page).not_to have_content('Alix')
      expect(page).not_to have_content('Casey')
    end

    it 'sorts rows when a column header is clicked, and reverses on a second click' do
      visit details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all')

      first_name_column = lambda do
        all('table.datatable tbody tr').map { |row| row.all('td')[1].text }
      end

      find('table.datatable thead th', text: 'First Name').click
      expect(first_name_column.call).to eq(['Alix', 'Blair', 'Casey'])

      find('table.datatable thead th', text: 'First Name').click
      expect(first_name_column.call).to eq(['Casey', 'Blair', 'Alix'])
    end
  end
end
