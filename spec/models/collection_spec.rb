###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  describe '#destroy_with_associated_records!' do
    let(:cohort) { create(:cohort) }
    let(:access_control) { cohort.viewable_access_control }
    let(:collection) { access_control.collection }
    let(:viewable_user_group) { cohort.system_viewable_user_group }
    let(:editable_user_group) { cohort.system_editable_user_group }

    it 'destroys the collection, both its access controls, and both its viewable and editable source user groups' do
      editable_access_control = cohort.editable_access_control
      access_control
      viewable_user_group
      editable_user_group

      collection.destroy_with_associated_records!

      expect(Collection.find_by(id: collection.id)).to be_nil
      expect(AccessControl.find_by(id: access_control.id)).to be_nil
      expect(AccessControl.find_by(id: editable_access_control.id)).to be_nil
      expect(UserGroup.find_by(id: viewable_user_group.id)).to be_nil
      expect(UserGroup.find_by(id: editable_user_group.id)).to be_nil
    end

    it 'does not touch a different source of the same type' do
      other_cohort = create(:cohort)
      other_user_group = other_cohort.system_viewable_user_group

      collection.destroy_with_associated_records!

      expect(UserGroup.find_by(id: other_user_group.id)).to be_present
    end

    it 'soft-deletes the collection and its dependents so they remain recoverable' do
      editable_access_control = cohort.editable_access_control
      access_control
      viewable_user_group
      editable_user_group

      collection.destroy_with_associated_records!

      # with_deleted.find raises RecordNotFound if a record was hard-deleted,
      # so these fail if destroy_all is ever swapped for really_destroy!.
      expect(Collection.with_deleted.find(collection.id)).to be_present
      expect(AccessControl.with_deleted.find(access_control.id)).to be_present
      expect(AccessControl.with_deleted.find(editable_access_control.id)).to be_present
      expect(UserGroup.with_deleted.find(viewable_user_group.id)).to be_present
      expect(UserGroup.with_deleted.find(editable_user_group.id)).to be_present
    end

    it 'does not destroy the shared role' do
      role = cohort.viewable_role
      access_control
      collection.destroy_with_associated_records!

      expect(Role.find_by(id: role.id)).to be_present
    end

    it 'does not error for a collection with no access controls or user groups' do
      plain_collection = create(:collection)

      expect { plain_collection.destroy_with_associated_records! }.not_to raise_error
      expect(Collection.find_by(id: plain_collection.id)).to be_nil
    end

    it 'does not touch unrelated user groups when the collection has no source' do
      plain_collection = create(:collection)
      unrelated_user_group = create(:user_group) # ordinary group, no source -- same shape as production data

      plain_collection.destroy_with_associated_records!

      expect(UserGroup.find_by(id: unrelated_user_group.id)).to be_present
    end
  end
end
