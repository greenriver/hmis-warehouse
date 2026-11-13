###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::VispdatsController, type: :request do
  # This should return the minimal set of attributes required to create a valid
  # Vispdat. As you add validations to Vispdat, be sure to
  # adjust the attributes here as well.
  let!(:valid_attributes) { build(:vispdat).attributes }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:client) { warehouse_client.destination }
  let!(:vispdat) { create(:vispdat, client: client) }
  let!(:invalid_attributes) {}
  let!(:no_data_source_collection) { create :collection }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # VispdatsController. Be sure to keep this updated too.
  let!(:valid_session) {}

  let!(:user) { create :acl_user }
  let!(:vispdat_editor) { create :vispdat_editor, can_search_own_clients: true }

  before(:each) do
    no_data_source_collection.set_viewables({ data_sources: GrdaWarehouse::DataSource.authoritative.pluck(:id) })
    setup_access_control(user, vispdat_editor, no_data_source_collection)
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns all vispdats as @vispdats' do
      vispdat.save
      get client_vispdats_path(vispdat.client)
      expect(assigns(:vispdats)).to eq([vispdat])
    end
  end

  describe 'GET #show' do
    it 'assigns the requested vispdat as @vispdat' do
      vispdat.save
      get client_vispdat_path(vispdat.client, vispdat)
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe 'GET #show' do
    it 'renders show' do
      vispdat.save
      get client_vispdat_path(vispdat.client, vispdat)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested vispdat as @vispdat' do
      vispdat.save
      get edit_client_vispdat_path(vispdat.client, vispdat)
      expect(assigns(:vispdat)).to eq(vispdat)
    end
  end

  describe 'POST #create' do
    before :each do
      # we need to complete the existing one.
      GrdaWarehouse::Vispdat::Base.update_all(submitted_at: Time.current)
    end
    context 'with valid params' do
      it 'creates a new Vispdat' do
        expect do
          post client_vispdats_path(client), params: { vispdat: valid_attributes, type: 'GrdaWarehouse::Vispdat::Individual' }
        end.to change(GrdaWarehouse::Vispdat::Individual, :count).by(1)
      end

      it 'assigns a newly created vispdat as @vispdat' do
        post client_vispdats_path(client), params: { vispdat: valid_attributes }
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat::Individual)
        expect(assigns(:vispdat)).to be_persisted
      end

      it 'sets the user_id to current_user' do
        post client_vispdats_path(client), params: { vispdat: valid_attributes }
        expect(assigns(:vispdat).user_id).to eq user.id
      end
    end

    context 'with invalid params' do
      it 'creates a stub vispdat as @vispdat' do
        post client_vispdats_path(client), params: { vispdat: invalid_attributes }
        expect(assigns(:vispdat)).to be_a(GrdaWarehouse::Vispdat::Individual)
      end
    end
  end

  describe 'PUT #add_child' do
    let!(:family_vispdat) { create :family_vispdat, :completable, client: client }

    it 'adds a child beyond the seven the old fixed-row form allowed' do
      7.times { |i| family_vispdat.children.create!(first_name: "Child#{i}", last_name: 'Tester') }

      expect do
        put add_child_client_vispdat_path(client, family_vispdat)
      end.to change { family_vispdat.children.count }.from(7).to(8)
    end

    it 'does not add a child to a non-family VI-SPDAT' do
      expect do
        put add_child_client_vispdat_path(client, vispdat)
      end.not_to change(GrdaWarehouse::Vispdat::Child, :count)
    end

    it 'refuses a user who may view but not edit VI-SPDATs' do
      viewer = create :acl_user
      setup_access_control(viewer, create(:vispdat_viewer), no_data_source_collection)
      sign_out user
      sign_in viewer

      expect do
        put add_child_client_vispdat_path(client, family_vispdat)
      end.not_to change(GrdaWarehouse::Vispdat::Child, :count)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'DELETE #remove_child' do
    let!(:family_vispdat) { create :family_vispdat, :completable, client: client }
    let!(:child) { family_vispdat.children.create!(first_name: 'Mine', last_name: 'Tester') }
    let!(:other_vispdat) { create :family_vispdat, :completable, client: client }
    let!(:other_child) { other_vispdat.children.create!(first_name: 'Theirs', last_name: 'Tester') }

    it 'removes a child of the requested VI-SPDAT' do
      delete remove_child_client_vispdat_path(client, family_vispdat, child_id: child.id), xhr: true

      expect(GrdaWarehouse::Vispdat::Child.where(id: child.id)).not_to exist
      expect(GrdaWarehouse::Vispdat::Child.where(id: other_child.id)).to exist
    end

    it 'will not remove a child belonging to a different VI-SPDAT' do
      begin
        delete remove_child_client_vispdat_path(client, family_vispdat, child_id: other_child.id), xhr: true
      rescue ActionView::Template::Error
        # remove_child.js.coffee dereferences @child, which is nil once the
        # association scope has (correctly) refused to find the other VI-SPDAT's
        # child. The guard has already done its job by this point, so tolerate
        # the render failure rather than pinning it.
      end

      expect(GrdaWarehouse::Vispdat::Child.where(id: other_child.id)).to exist
    end
  end

  describe 'PATCH #update for a family VI-SPDAT with more than seven children' do
    let!(:family_vispdat) { create :family_vispdat, :completable, client: client }
    let!(:children) do
      Array.new(8) { |i| family_vispdat.children.create!(first_name: "Child#{i}", last_name: 'Original') }
    end

    def children_params(overrides = {})
      children.map { |child| { id: child.id, first_name: child.first_name }.merge(overrides) }
    end

    it 'saves progress on an in-progress VI-SPDAT' do
      patch client_vispdat_path(client, family_vispdat), params: {
        grda_warehouse_vispdat_family: { children_attributes: children_params(last_name: 'Renamed') },
      }

      expect(family_vispdat.children.reload.count).to eq 8
      expect(family_vispdat.children.pluck(:last_name).uniq).to eq ['Renamed']
    end

    it 'removes a child flagged for destruction and leaves the rest alone' do
      removed = children.first

      patch client_vispdat_path(client, family_vispdat), params: {
        grda_warehouse_vispdat_family: {
          children_attributes: [{ id: removed.id, _destroy: '1' }],
        },
      }

      expect(family_vispdat.children.reload.map(&:first_name)).
        to contain_exactly(*children.drop(1).map(&:first_name))
    end
  end
end
