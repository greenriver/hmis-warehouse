###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

RSpec.describe ClientAccessControl::HistoryController, type: :request do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let(:destination) { non_window_destination_client }
  let(:base_permissions) { { can_view_clients: true, can_search_own_clients: true, can_view_client_name: true, can_view_full_client_dashboard: true } }

  def grant(**permissions)
    setup_access_control(user, create(:role, **base_permissions, **permissions), non_window_project_viewable_collection)
  end

  before { sign_in user }

  describe 'GET show' do
    it 'renders the calendar when the role grants the history calendar' do
      grant(can_view_client_history_calendar: true)

      get client_history_path(destination)

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).css('.client__calendar').size).to eq(1)
    end

    it 'redirects to the user root when the role lacks the history calendar permission' do
      grant

      get client_history_path(destination)

      expect(response).to redirect_to(user.my_root_path)
    end

    it 'shows the PDF form when the role grants homeless verification PDFs' do
      grant(can_view_client_history_calendar: true, can_generate_homeless_verification_pdfs: true)

      get client_history_path(destination)

      expect(response.body).to include('Generate Homeless Verification PDF')
    end

    it 'hides the PDF form from a role with file access but no PDF permission' do
      grant(can_view_client_history_calendar: true, can_see_own_file_uploads: true, can_manage_window_client_files: true)

      get client_history_path(destination)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Generate Homeless Verification PDF')
    end
  end

  describe 'POST queue' do
    it 'enqueues the verification job when the role grants homeless verification PDFs' do
      grant(can_view_client_history_calendar: true, can_generate_homeless_verification_pdfs: true)

      expect do
        post queue_client_history_path(destination), params: { pdf: { years: 2 } }
      end.to have_enqueued_job(ServiceHistory::ChronicVerificationJob).with(client_id: destination.id, years: 2, user_id: user.id)
    end

    it 'rejects the request without flagging the client when the role lacks the PDF permission' do
      grant(can_view_client_history_calendar: true, can_see_own_file_uploads: true)

      expect do
        post queue_client_history_path(destination), params: { pdf: { years: 2 } }
      end.not_to have_enqueued_job(ServiceHistory::ChronicVerificationJob)

      expect(response).to redirect_to(user.my_root_path)
      expect(destination.reload.generate_manual_history_pdf).to eq(false)
    end

    it 'rejects the request without flagging the client when the role grants the PDF permission but not the history calendar' do
      grant(can_generate_homeless_verification_pdfs: true)

      expect do
        post queue_client_history_path(destination), params: { pdf: { years: 2 } }
      end.not_to have_enqueued_job(ServiceHistory::ChronicVerificationJob)

      expect(response).to redirect_to(user.my_root_path)
      expect(destination.reload.generate_manual_history_pdf).to eq(false)
    end
  end

  describe 'when the feature permissions come from a project the client is not enrolled in' do
    before do
      grant
      setup_access_control(
        user,
        create(:role, **base_permissions, can_view_client_history_calendar: true, can_generate_homeless_verification_pdfs: true),
        window_project_viewable_collection,
      )
    end

    it 'redirects the history page even though the user holds both permissions elsewhere' do
      expect(user.can_view_client_history_calendar?).to eq(true)
      expect(user.can_generate_homeless_verification_pdfs?).to eq(true)

      get client_history_path(destination)

      expect(response).to redirect_to(user.my_root_path)
    end

    it 'rejects queue without enqueuing the verification job' do
      expect do
        post queue_client_history_path(destination), params: { pdf: { years: 2 } }
      end.not_to have_enqueued_job(ServiceHistory::ChronicVerificationJob)

      expect(response).to redirect_to(user.my_root_path)
    end

    it 'omits the History tab on the client dashboard' do
      get client_path(destination)

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).css("a[href='#{client_history_path(destination)}']").size).to eq(0)
    end
  end

  describe 'History tab on the client dashboard' do
    def history_tab_links
      Nokogiri::HTML(response.body).css("a[href='#{client_history_path(destination)}']").map { |a| a.text.strip }
    end

    it 'links to History when the role grants the history calendar' do
      grant(can_view_client_history_calendar: true)

      get client_path(destination)

      expect(history_tab_links).to eq(['History'])
    end

    it 'omits the History link when the role lacks the history calendar permission' do
      grant

      get client_path(destination)

      expect(response).to have_http_status(:ok)
      expect(history_tab_links).to eq([])
    end

    context 'with the VA client dashboard' do
      before do
        config.update!(client_dashboard: 'va')
        GrdaWarehouse::Config.invalidate_cache
      end

      it 'links to History when the role grants the history calendar' do
        grant(can_view_client_history_calendar: true)

        get client_path(destination)

        expect(history_tab_links).to eq(['History'])
      end

      it 'omits the History link when the role lacks the history calendar permission' do
        grant

        get client_path(destination)

        expect(response).to have_http_status(:ok)
        expect(history_tab_links).to eq([])
      end
    end
  end
end
