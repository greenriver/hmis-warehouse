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
      get source_data_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects show to login' do
      get source_datum_path(id: item.id, type: 'Client')
      expect(response).to redirect_to(new_user_session_path)
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
        allow(GrdaWarehouse::DataSource).to receive(:editable_by).with(user).and_return(
          GrdaWarehouse::DataSource.all,
        )
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

        context 'with HMIS data source' do
          let(:hmis_data_source) { create(:hmis_data_source) }
          let!(:hmis_item) { create(:grda_warehouse_hud_client, data_source: hmis_data_source) }

          before do
            user_group.add(user)
            create(:access_control, role: role, collection: collection, user_group: user_group)
            collection.set_viewables({ data_sources: [hmis_data_source.id] })
          end

          it 'assigns hmis variables' do
            get source_datum_path(id: hmis_item.id, type: 'Client')
            expect(assigns(:hmis)).to be true
            expect(assigns(:hmis_url)).to be_present
            expect(assigns(:importers)).to be_nil
          end
        end

        context 'with imported data source' do
          let!(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }

          it 'assigns importer variables' do
            get source_datum_path(id: item.id, type: 'Client')
            expect(assigns(:hmis)).to be_falsy
            expect(assigns(:importers)).to be_present
            expect(assigns(:importer)).to eq(importer_log)
          end
        end
      end
    end
  end
end
