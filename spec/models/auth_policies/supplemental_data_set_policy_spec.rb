# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::SupplementalDataSetPolicy, type: :model do
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  let(:data_set) { create(:hmis_supplemental_data_set, data_source: data_source) }
  let(:policy) { user.policy_for(data_set) }
  
  let(:role) { create(:role, can_view_supplemental_client_data: true) }
  let(:user_group) { create(:user_group) }
  let(:ds_collection) { create(:collection) }
  let(:set_collection) { create(:collection) }

  before do
    user_group.add(user)
  end

  context 'with access to both data source and data set' do
    before do
      create(:access_control, role: role, collection: ds_collection, user_group: user_group)
      ds_collection.set_viewables({ data_sources: [data_source.id] })
      
      create(:access_control, role: role, collection: set_collection, user_group: user_group)
      set_collection.set_viewables({ supplemental_data_sets: [data_set.id] })
    end

    it 'grants access' do
      expect(policy.can_view?).to be true
    end
  end

  context 'with access to only data set' do
    before do
      create(:access_control, role: role, collection: set_collection, user_group: user_group)
      set_collection.set_viewables({ supplemental_data_sets: [data_set.id] })
    end

    it 'denies access' do
      expect(policy.can_view?).to be false
    end
  end

  context 'with access to only data source' do
    before do
      create(:access_control, role: role, collection: ds_collection, user_group: user_group)
      ds_collection.set_viewables({ data_sources: [data_source.id] })
    end

    it 'denies access' do
      expect(policy.can_view?).to be false
    end
  end

  context 'for legacy user' do
    let(:user) { create(:user) }
    it 'denies access' do
      expect(policy.can_view?).to be false
    end
  end
end
