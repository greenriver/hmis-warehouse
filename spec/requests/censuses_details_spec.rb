###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_contexts/hud_enrollment_builders'

RSpec.describe 'CensusesController#details', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report) { create(:touch_point_report, url: 'censuses', name: 'Census') }

  let!(:hmis_user) { create(:hmis_user, data_source: destination_data_source) }
  let!(:project) { create_project(project_type: 1) } # ES Night-by-Night
  let!(:restricted_client) { create_client_with_warehouse_link(first_name: 'Restricted', last_name: 'Client') }
  let!(:enrollment) { create_enrollment(client: restricted_client, project: project, entry_date: Date.current) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)

    create_bed_night_service(enrollment: enrollment, date: Date.current)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    Hmis::Hud::Client.find(restricted_client.id).mark_as_restricted!(user: hmis_user)

    sign_in user
  end

  def details_params(format: :html)
    {
      date: Date.current.to_s,
      census_detail_slug: 'all-all-all',
      filters: { start: 1.month.ago.to_date, end: Date.current, project_ids: [project.id] },
      format: format,
    }
  end

  it 'redacts the restricted client name in the html view' do
    get details_censuses_path(details_params)

    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
  end

  def rendered_workbook
    excel_file = Tempfile.new(['census_details', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client name in the Excel export' do
    get details_censuses_path(details_params(format: :xlsx))

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
    expect(rows.flatten).not_to include('Restricted')
    expect(rows.flatten).to include('Name Redacted')
  end
end
