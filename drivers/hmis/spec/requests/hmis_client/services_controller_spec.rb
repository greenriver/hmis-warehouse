###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hidden_project_enrollment_context'

RSpec.describe HmisClient::ServicesController, type: :request do
  include_context 'hidden project enrollment context'

  let!(:visible_service) { create(:hmis_custom_service, data_source: ds, client: hmis_client, enrollment: visible_enrollment, DateProvided: Date.new(2024, 3, 3)) }
  let!(:hidden_service) { create(:hmis_custom_service, data_source: ds, client: hmis_client, enrollment: hidden_enrollment, DateProvided: Date.new(2023, 4, 4)) }

  context 'when the user can view the client through the visible project' do
    before { sign_in_with(viewer_role) }

    it 'shows the service recorded at the visible project' do
      get hmis_client_client_service_path(destination, visible_service)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_service.DateProvided.to_s)
    end

    it 'does not show the service recorded at a project outside the collection' do
      # The client is visible and only the hidden enrollment is excluded, so only the enrollment check can refuse.
      expect(destination.show_demographics_to?(user)).to be(true)
      expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: [visible_enrollment.id, hidden_enrollment.id]).pluck(:id)).to contain_exactly(visible_enrollment.id)

      get hmis_client_client_service_path(destination, hidden_service)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(hidden_service.DateProvided.to_s)
    end
  end

  context 'when the user can search the client but not view it' do
    before { sign_in_with(search_only_role) }

    it 'does not show the service' do
      # Searchable but not viewable. Without can_view_clients the user sees none of the
      # client's enrollments either, so the client scope and the enrollment check both refuse.
      expect(GrdaWarehouse::Hud::Client.destination_from_searchable_to(user).pluck(:id)).to include(destination.id)
      expect(destination.show_demographics_to?(user)).to be(false)
      expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: visible_enrollment.id)).to be_empty

      get hmis_client_client_service_path(destination, visible_service)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(visible_service.DateProvided.to_s)
    end
  end
end
