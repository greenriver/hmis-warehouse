###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'

RSpec.describe OrganizationsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  let!(:export) { create(:hud_export, data_source: data_source, ExportID: 'DS1') }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let(:writer_role) do
    create(
      :role,
      can_view_projects: true,
      can_edit_organizations: true,
      can_delete_projects: true,
      can_delete_data_sources: true,
    )
  end
  let(:viewer_role) { create(:role, can_view_projects: true) }

  def collection_with(viewables)
    create(:collection).tap { |collection| collection.set_viewables(viewables) }
  end

  def expect_not_authorized
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to be_present
  end

  describe 'with write rights on the organization' do
    before do
      setup_access_control(user, writer_role, collection_with(organizations: [organization.id]))
      sign_in user
    end

    it 'updates the organization' do
      patch organization_path(organization), params: { organization: { confidential: '1' } }
      expect(response).to redirect_to(data_source_path(data_source))
      expect(organization.reload.confidential).to be(true)
    end

    it 'queues the delete' do
      expect { delete organization_path(organization) }.
        to have_enqueued_job(DeleteItemJob).with(item_id: organization.id, item_class: 'GrdaWarehouse::Hud::Organization')
    end
  end

  it 'does not queue the delete with only Can Delete Projects granted on the data source' do
    delete_projects_role = create(:role, can_view_projects: true, can_delete_projects: true)
    setup_access_control(user, delete_projects_role, collection_with(data_sources: [data_source.id]))
    sign_in user

    expect { delete organization_path(organization) }.not_to have_enqueued_job(DeleteItemJob)
    expect_not_authorized
  end

  # The writer role grants every permission the actions check, so only the per-record policy
  # checks stop writes to an organization the user reaches only through one of its projects.
  describe 'with write rights in another collection and view rights on one project' do
    let(:other_organization) { create(:hud_organization, data_source: create(:source_data_source)) }

    before do
      setup_access_control(user, writer_role, collection_with(organizations: [other_organization.id]))
      setup_access_control(user, viewer_role, collection_with(projects: [project.id]))
      sign_in user
    end

    it 'does not queue the delete' do
      expect { delete organization_path(organization) }.not_to have_enqueued_job(DeleteItemJob)
      expect_not_authorized
    end

    it 'does not update the organization' do
      patch organization_path(organization), params: { organization: { confidential: '1' } }
      expect_not_authorized
      expect(organization.reload.confidential).to be(false)
    end

    it 'denies edit' do
      get edit_organization_path(organization)
      expect_not_authorized
    end

    it 'shows no edit or delete buttons for the organization on the data source page' do
      get data_source_path(data_source)
      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      organization_headers = page.css('h3').map { |header| header.text.strip }
      expect(organization_headers).to include(a_string_including(organization.OrganizationName))
      expect(page.css("a[href='#{edit_organization_path(organization)}']")).to be_empty
      expect(page.css("a[data-method='delete'][href='#{organization_path(organization)}']")).to be_empty
    end
  end

  it 'shows the edit and delete buttons for an organization the role covers' do
    setup_access_control(user, writer_role, collection_with(organizations: [organization.id]))
    sign_in user

    get data_source_path(data_source)
    page = Nokogiri::HTML(response.body)
    expect(page.css("a[href='#{edit_organization_path(organization)}']").size).to eq(1)
    expect(page.css("a[data-method='delete'][href='#{organization_path(organization)}']").size).to eq(1)
  end

  it 'does not find an organization the user cannot view' do
    sign_in user
    patch organization_path(organization), params: { organization: { confidential: '1' } }
    expect(response).to have_http_status(:not_found)
  end
end
