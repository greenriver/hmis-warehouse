###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Data quality report token access', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:other_user) { create(:acl_user) }
  let!(:third_user) { create(:acl_user) }
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { create(:dq_project_group) }
  let!(:contact) { create(:grda_warehouse_contact_project, id: next_contact_id, user: user, entity: project) }

  # Contact and user ids come from separate sequences and can match by chance, which would let a
  # contact token pass the requestor check. Contacts get ids above every existing user and contact id.
  def next_contact_id
    @next_contact_id ||= [User.unscoped.maximum(:id), GrdaWarehouse::Contact::Base.unscoped.maximum(:id)].compact.max.to_i
    @next_contact_id += 1
  end

  let!(:project_report) { create(:data_quality_report_version_five, project: project, report: { 'source' => 'project report' }) }
  let!(:other_project_report) { create(:data_quality_report_version_five, project: other_project) }
  let!(:sibling_project_report) { create(:data_quality_report_version_five, project: project) }
  let!(:group_report) { create(:data_quality_report_version_five, project_group: project_group, report: { 'source' => 'group report' }) }
  let!(:other_group_report) { create(:data_quality_report_version_five, project_group: project_group) }

  def token_for(report, contact_id: contact.id)
    GrdaWarehouse::ReportToken.create!(report_id: report.id, contact_id: contact_id)
  end

  let!(:project_token) { token_for(project_report) }
  let!(:group_token) { token_for(group_report) }

  def project_url(action, token, report, project_id: project.id)
    helper = {
      show: :notification_project_data_quality_report_path,
      answers: :answers_notification_project_data_quality_report_path,
      support: :support_notification_project_data_quality_report_path,
    }.fetch(action)
    public_send(helper, token.token, project_id, report.id)
  end

  def group_url(action, token, report)
    helper = {
      show: :notification_project_group_data_quality_report_path,
      answers: :answers_notification_project_group_data_quality_report_path,
      support: :support_notification_project_group_data_quality_report_path,
    }.fetch(action)
    public_send(helper, token.token, project_group.id, report.id)
  end

  context 'when logged out' do
    shared_examples 'requires sign-in' do
      it 'for show' do
        expect_unauthenticated_warehouse_request { get(url_for_action.call(:show)) }
      end

      it 'for answers' do
        expect_unauthenticated_warehouse_request { get(url_for_action.call(:answers)) }
      end
    end

    context 'with a project report token' do
      let(:url_for_action) { ->(action) { project_url(action, project_token, project_report) } }

      it_behaves_like 'requires sign-in'
    end

    context 'with a project group report token' do
      let(:url_for_action) { ->(action) { group_url(action, group_token, group_report) } }

      it_behaves_like 'requires sign-in'
    end

    it 'remembers the token URL as the post-sign-in destination', :devise_only do
      url = project_url(:show, project_token, project_report)
      get url

      expect(session['user_return_to']).to eq(url)
    end
  end

  context 'when signed in as a different user than the token contact' do
    before { sign_in(other_user) }

    [:show, :answers].each do |action|
      it "returns 404 for #{action} of a project report token" do
        get project_url(action, project_token, project_report)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for #{action} of a project group report token" do
        get group_url(action, group_token, group_report)
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns 404 when the token contact_id is the signed-in user id and no contact has that id' do
      token = token_for(project_report, contact_id: other_user.id)
      get project_url(:show, token, project_report)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when the token contact is soft-deleted' do
    before do
      sign_in(user)
      contact.destroy
    end

    it 'returns 404 for the contact user' do
      get project_url(:show, project_token, project_report)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with a requestor token' do
    let!(:requested_report) { create(:data_quality_report_version_five, project: project, requestor_id: other_user.id) }
    let!(:requestor_token) { token_for(requested_report, contact_id: other_user.id) }

    it 'shows the report to the requestor' do
      sign_in(other_user)
      get project_url(:show, requestor_token, requested_report)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for another user' do
      sign_in(user)
      get project_url(:show, requestor_token, requested_report)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for the user of an unrelated contact whose id equals the requestor id' do
      create(:grda_warehouse_contact_project, id: other_user.id, user: third_user, entity: other_project)
      sign_in(third_user)
      get project_url(:show, requestor_token, requested_report)
      expect(response).to have_http_status(:not_found)
    end

    it 'shows the report to the user of a contact on the report project whose id equals the requestor id' do
      create(:grda_warehouse_contact_project, id: other_user.id, user: third_user, entity: project)
      sign_in(third_user)
      get project_url(:show, requestor_token, requested_report)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for a user whose id is the token contact_id but who is not the report requestor' do
      token = token_for(project_report, contact_id: other_user.id)
      sign_in(other_user)
      get project_url(:show, token, project_report)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when signed in as the token contact without project or report access' do
    before { sign_in(user) }

    it 'shows the project report for its own token' do
      get project_url(:show, project_token, project_report)

      expect(response).to have_http_status(:ok)
    end

    it 'shows the project group report for its own token' do
      get group_url(:show, group_token, group_report)

      expect(response).to have_http_status(:ok)
    end

    it 'returns project report answers for its own token' do
      get project_url(:answers, project_token, project_report)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('source' => 'project report')
    end

    it 'returns project group report answers for its own token' do
      get group_url(:answers, group_token, group_report)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('source' => 'group report')
    end

    [:show, :answers, :support].each do |action|
      it "returns 404 for #{action} of another report on the same project" do
        get project_url(action, project_token, sibling_project_report)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for #{action} of a report on another project" do
        get project_url(action, project_token, other_project_report, project_id: other_project.id)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for #{action} of another report in the same project group" do
        get group_url(action, group_token, other_group_report)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for #{action} when the URL project is not the token's report project" do
        get project_url(action, project_token, project_report, project_id: other_project.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    [:show, :answers].each do |action|
      it "returns 404 for #{action} with an expired token on its own project report" do
        project_token.update_columns(expires_at: 1.day.ago)

        get project_url(action, project_token, project_report)

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for #{action} with an expired token on its own project group report" do
        group_token.update_columns(expires_at: 1.day.ago)

        get group_url(action, group_token, group_report)

        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns 404 for an unknown token' do
      unknown = GrdaWarehouse::ReportToken.new(token: 'unknown', report_id: project_report.id)

      get project_url(:show, unknown, project_report)
      expect(response).to have_http_status(:not_found)
    end
  end
end
