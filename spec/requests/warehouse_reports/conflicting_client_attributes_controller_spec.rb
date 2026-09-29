###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::ConflictingClientAttributesController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/conflicting_client_attributes', name: 'Conflicting Client Attributes') }
  let!(:project) { create_project(project_type: 1) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def link_source(destination, dob:, in_project: project)
    source = create(:hud_client, data_source: in_project.data_source, dob: dob)
    create_enrollment(client: source, project: in_project, entry_date: 1.year.ago.to_date)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.PersonalID)
    source
  end

  def build_destination(first_name)
    create(:grda_warehouse_hud_client, FirstName: first_name, LastName: 'Coverage', data_source: destination_data_source)
  end

  it 'lists every destination whose visible sources disagree on DOB' do
    conflicting = Array.new(preload_miss_client_count) do |i|
      build_destination("Conflict#{i}").tap do |destination|
        link_source(destination, dob: Date.new(1980, 1, 1))
        link_source(destination, dob: Date.new(1981, 2, 2))
      end
    end

    get warehouse_reports_conflicting_client_attributes_path

    expect(response).to have_http_status(:ok)
    conflicting.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'omits a destination whose visible sources agree on DOB' do
    build_destination('Discordant').tap do |destination|
      link_source(destination, dob: Date.new(1980, 1, 1))
      link_source(destination, dob: Date.new(1981, 2, 2))
    end
    build_destination('Agreeing').tap do |destination|
      link_source(destination, dob: Date.new(1990, 3, 3))
      link_source(destination, dob: Date.new(1990, 3, 3))
    end

    get warehouse_reports_conflicting_client_attributes_path

    expect(response.body).to include('Discordant')
    expect(response.body).not_to include('Agreeing')
  end

  it 'omits a destination whose only conflicting source is not visible to the user' do
    hidden_project = create_project(project_type: 1)
    build_destination('Discordant').tap do |destination|
      link_source(destination, dob: Date.new(1980, 1, 1))
      link_source(destination, dob: Date.new(1981, 2, 2))
    end
    build_destination('Hiddenconflict').tap do |destination|
      link_source(destination, dob: Date.new(1990, 3, 3))
      link_source(destination, dob: Date.new(1991, 4, 4), in_project: hidden_project)
    end

    get warehouse_reports_conflicting_client_attributes_path

    expect(response.body).to include('Discordant')
    expect(response.body).not_to include('Hiddenconflict')
  end
end
