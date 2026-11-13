###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# EntityAccess is a concern; exercise it through a concrete host (Cohort),
# which supports both viewable and editable access controls.
RSpec.describe EntityAccess, type: :model do
  describe '#remove_system_collections!' do
    let(:cohort) { create(:cohort) }

    it 'soft-deletes the system collection, its access controls, and its source user groups' do
      viewable_ac = cohort.viewable_access_control
      editable_ac = cohort.editable_access_control
      collection = viewable_ac.collection
      viewable_ug = cohort.system_viewable_user_group
      editable_ug = cohort.system_editable_user_group

      cohort.remove_system_collections!

      expect(Collection.find_by(id: collection.id)).to be_nil
      expect(AccessControl.find_by(id: viewable_ac.id)).to be_nil
      expect(AccessControl.find_by(id: editable_ac.id)).to be_nil
      expect(UserGroup.find_by(id: viewable_ug.id)).to be_nil
      expect(UserGroup.find_by(id: editable_ug.id)).to be_nil
    end

    it 'does not touch the system collection of a different entity of the same type' do
      cohort.viewable_access_control
      other_cohort = create(:cohort)
      other_ac = other_cohort.viewable_access_control
      other_collection = other_ac.collection
      other_ug = other_cohort.system_viewable_user_group

      cohort.remove_system_collections!

      # Guards the source scope: a source_type-only (source_id-dropped) query would
      # sweep every same-type entity's collection, not just this cohort's.
      expect(Collection.find_by(id: other_collection.id)).to be_present
      expect(AccessControl.find_by(id: other_ac.id)).to be_present
      expect(UserGroup.find_by(id: other_ug.id)).to be_present
    end

    it 'leaves the shared role intact' do
      role = cohort.viewable_role
      cohort.viewable_access_control

      cohort.remove_system_collections!

      expect(Role.find_by(id: role.id)).to be_present
    end

    it 'creates nothing when the entity has no system collection' do
      cohort # created, but no access control / collection forced

      expect { cohort.remove_system_collections! }.not_to change(Collection, :count)
      # with_deleted catches the forbidden system_collection path, which would
      # first_or_initialize + persist a row and then soft-delete it in the same call,
      # leaving a soft-deleted row invisible to the default scope but visible here.
      expect(Collection.with_deleted.where(source: cohort)).to be_empty
    end

    it 'rescues, logs, and reports errors instead of raising' do
      cohort.viewable_access_control
      allow_any_instance_of(Collection).to receive(:destroy_with_associated_records!).and_raise(StandardError, 'boom')
      expect(Sentry).to receive(:capture_exception_with_info) do |error, *|
        expect(error).to be_a(StandardError)
        expect(error.message).to eq('boom')
      end

      expect { cohort.remove_system_collections! }.not_to raise_error
    end
  end
end
