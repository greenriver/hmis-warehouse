###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SourceDataController, type: :request do
  let(:data_source) { create(:authoritative_data_source) }
  let!(:item) { create(:grda_warehouse_hud_client, data_source: data_source) }
  let(:user) { create(:acl_user) }
  let!(:access_control) do
    hmis_user = user.related_hmis_user(data_source)
    create_access_control(hmis_user, data_source, with_permission: [:can_view_clients])
  end

  describe 'logged out' do
    it 'redirects index to login' do
      expect_unauthenticated_warehouse_request do
        get source_data_path
      end
    end

    it 'redirects show to login' do
      expect_unauthenticated_warehouse_request do
        get source_datum_path(id: item.id, type: 'Client')
      end
    end
  end

  describe 'logged in' do
    context 'without permission' do
      before { sign_in user }

      it 'redirects index to root' do
        get source_data_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it 'redirects show to root' do
        get source_datum_path(id: item.id, type: 'Client')
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'with permission' do
      let(:role) { create(:role, can_upload_hud_zips: true, can_edit_data_sources: true, can_view_projects: true, can_view_clients: true) }
      let(:user_group) { create(:user_group) }
      let(:collection) { create(:collection) }

      before do
        user_group.add(user)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ data_sources: [data_source.id] })
        sign_in user
      end

      describe 'GET /index' do
        it 'renders the index template' do
          get source_data_path
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:index)
        end
      end

      describe 'GET /show' do
        it 'renders the show template' do
          get source_datum_path(id: item.id, type: 'Client')
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        context 'for a record in a data source the user cannot edit' do
          let(:other_data_source) { create(:authoritative_data_source) }
          let!(:other_item) { create(:grda_warehouse_hud_client, data_source: other_data_source) }

          it 'responds not found' do
            get source_datum_path(id: other_item.id, type: 'Client')
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'with HMIS data source' do
          let(:hmis_data_source) { create(:hmis_data_source) }
          let!(:hmis_item) { create(:grda_warehouse_hud_client, data_source: hmis_data_source) }

          before do
            collection.set_viewables({ data_sources: [hmis_data_source.id] })
          end

          it 'marks the record HMIS-managed and shows no import columns' do
            get source_datum_path(id: hmis_item.id, type: 'Client')
            expect(assigns(:hmis)).to be true
            expect(assigns(:hmis_url)).to be_nil # user lacks access to view client in HMIS
            expect(assigns(:imported)).to be false
            expect(assigns(:csv)).to be false
            expect(response.body).not_to include('CSV Value')
          end

          context 'and user has permission to view the client in OP HMIS' do
            before do
              hmis_user = user.related_hmis_user(hmis_data_source)
              create_access_control(hmis_user, hmis_data_source, with_permission: [:can_view_clients])
            end
            it 'shows a link to the client profile in OP HMIS' do
              get source_datum_path(id: hmis_item.id, type: 'Client')
              expect(assigns(:hmis)).to be true
              expect(assigns(:hmis_url)).to be_present
            end
          end
        end

        context 'with imported data source' do
          def create_importer_row(importer_log, klass: HmisCsvTwentyTwentyFour::Importer::Client)
            klass.create!(
              PersonalID: item.PersonalID,
              data_source_id: item.data_source_id,
              importer_log_id: importer_log.id,
              pre_processed_at: importer_log.created_at,
              source_id: item.id,
              source_type: item.class.name,
            )
          end

          def create_loader_row(importer_log, **attrs)
            HmisCsvTwentyTwentyFour::Loader::Client.create!(
              PersonalID: item.PersonalID,
              data_source_id: item.data_source_id,
              loader_id: importer_log.id,
              loaded_at: importer_log.created_at,
              **attrs,
            )
          end

          it 'shows only the warehouse column when no staging rows survive for this record' do
            get source_datum_path(id: item.id, type: 'Client')
            expect(response).to have_http_status(:success)
            expect(assigns(:hmis)).to be_falsy
            expect(assigns(:imported)).to be_nil
            expect(assigns(:csv)).to be_nil
            expect(response.body).not_to include('Post-Processed Value')
            expect(response.body).not_to include('CSV Value')
          end

          context 'and the record has a staging row from an importer run that is no longer recent' do
            let!(:stale_importer_log) { create(:hmis_csv_importer_log, data_source: data_source, created_at: 3.years.ago) }
            let!(:staging_row) { create_importer_row(stale_importer_log) }
            let!(:loaded_row) { create_loader_row(stale_importer_log) }
            before do
              # Ten newer runs that never re-imported this record.
              create_list(:hmis_csv_importer_log, 10, data_source: data_source)
            end

            it 'assigns the surviving staging rows and renders their columns' do
              get source_datum_path(id: item.id, type: 'Client')
              expect(assigns(:hmis)).to be_falsy
              expect(assigns(:year)).to eq('2024')
              expect(assigns(:imported)).to eq(staging_row)
              expect(assigns(:csv)).to eq(loaded_row)
              expect(response.body).to include('Post-Processed Value')
              expect(response.body).to include('CSV Value')
            end
          end

          context 'and the record has staging rows from several importer runs in the same year' do
            let!(:older_log) { create(:hmis_csv_importer_log, data_source: data_source, created_at: 2.days.ago) }
            let!(:newer_log) { create(:hmis_csv_importer_log, data_source: data_source, created_at: 1.day.ago) }
            let!(:older_importer_row) { create_importer_row(older_log) }
            let!(:newer_importer_row) { create_importer_row(newer_log) }
            let!(:older_loader_row) { create_loader_row(older_log) }
            let!(:newer_loader_row) { create_loader_row(newer_log) }

            it 'assigns the rows from the most recent run' do
              get source_datum_path(id: item.id, type: 'Client')
              expect(assigns(:imported)).to eq(newer_importer_row)
              expect(assigns(:csv)).to eq(newer_loader_row)
            end
          end

          context 'and only a soft-deleted loader row survives' do
            let!(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
            let!(:deleted_loader_row) { create_loader_row(importer_log, DateDeleted: 1.day.ago) }

            it 'assigns the deleted CSV row and no post-processed row' do
              get source_datum_path(id: item.id, type: 'Client')
              expect(assigns(:year)).to eq('2024')
              expect(assigns(:imported)).to be_nil
              expect(assigns(:csv)).to eq(deleted_loader_row)
              expect(response.body).to include('CSV Value')
              expect(response.body).not_to include('Post-Processed Value')
            end
          end
        end
      end
    end
  end
end
