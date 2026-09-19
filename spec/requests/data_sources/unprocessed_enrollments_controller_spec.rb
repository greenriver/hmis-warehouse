###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSources::UnprocessedEnrollmentsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:source_data_source) }
  let(:destination_data_source) { create(:destination_data_source) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }

  def create_linked_client(within_data_source)
    source_client = create(:grda_warehouse_hud_client, data_source: within_data_source)
    destination_client = source_client.dup
    destination_client.data_source = destination_data_source
    destination_client.save!
    create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
    source_client
  end

  describe 'GET #index' do
    it 'redirects unauthenticated users to sign in' do
      expect_unauthenticated_warehouse_request do
        get data_source_unprocessed_enrollments_path(data_source)
      end
    end

    it 'denies users who cannot view projects, organizations, or imports' do
      sign_in user
      get data_source_unprocessed_enrollments_path(data_source)
      expect(response).to redirect_to(root_path)
    end

    context 'with permission but no access to this data source' do
      before do
        setup_access_control(user, role, collection)
        sign_in user
      end

      it 'returns not found for a data source outside the viewable scope' do
        get data_source_unprocessed_enrollments_path(data_source)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with permission and access to the data source' do
      before do
        collection.set_viewables({ data_sources: [data_source.id] })
        setup_access_control(user, role, collection)
        sign_in user
      end

      describe 'filtering' do
        let!(:eligible_enrollment) do
          create(:hud_enrollment, data_source: data_source, project: project, client: create_linked_client(data_source), processed_as: nil)
        end
        let!(:processed_enrollment) do
          create(:hud_enrollment, data_source: data_source, project: project, client: create_linked_client(data_source), processed_as: { 'a' => 1 })
        end
        let!(:enrollment_missing_destination_client) do
          client_without_destination = create(:grda_warehouse_hud_client, data_source: data_source)
          create(:hud_enrollment, data_source: data_source, project: project, client: client_without_destination, processed_as: nil)
        end
        let!(:enrollment_missing_project) do
          create(:hud_enrollment, data_source: data_source, client: create_linked_client(data_source), processed_as: nil)
        end
        let!(:other_data_source) { create(:source_data_source, name: 'Other Vendor') }
        let!(:other_data_source_enrollment) do
          other_project = create(:grda_warehouse_hud_project, data_source: other_data_source)
          create(:hud_enrollment, data_source: other_data_source, project: other_project, client: create_linked_client(other_data_source), processed_as: nil)
        end

        it 'renders only the enrollment that is unprocessed with a resolvable project and destination client' do
          get data_source_unprocessed_enrollments_path(data_source)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("<td>#{eligible_enrollment.id}</td>")
          expect(response.body).not_to include("<td>#{processed_enrollment.id}</td>")
          expect(response.body).not_to include("<td>#{enrollment_missing_destination_client.id}</td>")
          expect(response.body).not_to include("<td>#{enrollment_missing_project.id}</td>")
          expect(response.body).not_to include("<td>#{other_data_source_enrollment.id}</td>")
        end

        it "matches DataSource#unprocessed_enrollment_count exactly, so the drill-down list can't disagree with the index page's count" do
          get data_source_unprocessed_enrollments_path(data_source)

          rendered_ids = response.body.scan(/<td>(\d+)<\/td>/).flatten.map(&:to_i)
          expect(rendered_ids).to contain_exactly(eligible_enrollment.id)
          expect(data_source.unprocessed_enrollment_count).to eq(rendered_ids.size)
        end
      end

      describe 'source data link' do
        let!(:enrollment) do
          create(:hud_enrollment, data_source: data_source, project: project, client: create_linked_client(data_source), processed_as: nil)
        end

        context 'when the user can upload HUD zips' do
          let(:role) { create(:role, can_view_projects: true, can_upload_hud_zips: true) }

          it 'links the Enrollment ID to its source data page' do
            get data_source_unprocessed_enrollments_path(data_source)
            expect(response.body).to include(%(href="/source_data/#{enrollment.id}?type=Enrollment"))
          end
        end

        context 'when the user cannot upload HUD zips' do
          it 'shows the Enrollment ID as plain text with no source data link' do
            get data_source_unprocessed_enrollments_path(data_source)
            expect(response.body).not_to include(source_datum_path(enrollment.id, type: 'Enrollment'))
            expect(response.body).to include("<td>#{enrollment.id}</td>")
          end
        end
      end

      describe 'pagination' do
        let!(:enrollments) do
          Array.new(26) do
            create(:hud_enrollment, data_source: data_source, project: project, client: create_linked_client(data_source), processed_as: nil)
          end
        end

        it 'splits results across pages of 25 with no overlap or omission' do
          get data_source_unprocessed_enrollments_path(data_source)
          page_one_ids = response.body.scan(/<td>(\d+)<\/td>/).flatten.map(&:to_i)
          expect(page_one_ids.size).to eq(25)

          get data_source_unprocessed_enrollments_path(data_source, page: 2)
          page_two_ids = response.body.scan(/<td>(\d+)<\/td>/).flatten.map(&:to_i)
          expect(page_two_ids.size).to eq(1)

          expect(page_one_ids + page_two_ids).to contain_exactly(*enrollments.map(&:id))
        end
      end

      describe 'client PII scoping' do
        let(:role) { create(:role, can_view_projects: true, can_view_clients: true, can_view_client_name: true) }

        before do
          # Narrows the outer before block's data-source-wide grant down to just `project`,
          # so `restricted_project` (below) is enrolled-in but not itself granted.
          collection.set_viewables({ projects: [project.id] })
        end

        let!(:shared_client) { create_linked_client(data_source) }
        let!(:restricted_project) { create(:grda_warehouse_hud_project, data_source: data_source) }
        # Not shown on this page (already processed) - exists only so the client is enrolled
        # in a project the user IS granted name-view on, which is what the old client-wide
        # pii_provider(user:) would (incorrectly) let leak onto the restricted row below.
        let!(:processed_enrollment_in_granted_project) do
          create(:hud_enrollment, data_source: data_source, project: project, client: shared_client, processed_as: { 'a' => 1 })
        end
        let!(:restricted_enrollment) do
          create(:hud_enrollment, data_source: data_source, project: restricted_project, client: shared_client, processed_as: nil)
        end

        it "redacts the client's name on a project the user has no PII access to, even though the same client is name-visible via a different project" do
          get data_source_unprocessed_enrollments_path(data_source)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("<td>#{restricted_enrollment.id}</td>")
          expect(response.body).not_to include(shared_client.FirstName)
          expect(response.body).not_to include(shared_client.LastName)
          expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        end
      end
    end
  end
end
