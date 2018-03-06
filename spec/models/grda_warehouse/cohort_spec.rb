require 'rails_helper'

RSpec.describe GrdaWarehouse::Cohort, type: :model do

  let(:cohort_manager) {create :cohort_manager}
  let(:cohort_editor) {create :cohort_client_editor}
  let(:cohort_viewer) {create :cohort_client_viewer}

  let(:user) { create :user }
  let(:admin) { create :user, roles: [cohort_manager]}
  let(:editor) { create :user, roles: [cohort_editor]}
  let(:viewer) { create :user, roles: [cohort_viewer]}

  let(:client) { create :hud_client }
  let(:cohort) { create :cohort }
  let(:cohort_2) { create :cohort }
  let(:cohort_client) { create :cohort_client, cohort: cohort, client: client }
  let(:adjusted_days_homeless) { build :adjusted_days_homeless, cohort: cohort }
  let(:rank) { build :rank, cohort: cohort }
  describe 'when a user with no roles accesses a cohort column' do
    it 'display_as_editable? should always return false' do
      expect( adjusted_days_homeless.display_as_editable?(user, cohort_client) ).to be_falsey
    end
    it 'display_as_editable? should always return false' do
      expect( rank.display_as_editable?(user, cohort_client) ).to be_falsey
    end
  end
  describe 'when a user with a cohort management role accesses a cohort column' do
    it 'display_as_editable? should always return true' do
      expect( adjusted_days_homeless.display_as_editable?(admin, cohort_client) ).to be true
    end
    it 'display_as_editable? should always return true' do
      expect( rank.display_as_editable?(admin, cohort_client) ).to be true
    end
  end

  describe 'when a user with a cohort editor role accesses a cohort column' do
    it 'display_as_editable? should return false if not cohorts have been assigned' do
      expect( adjusted_days_homeless.display_as_editable?(editor, cohort_client) ).to be_falsey
    end
    it 'display_as_editable? should return true if cohorts have been assigned' do
      GrdaWarehouse::UserViewableEntity.create(user_id: editor.id, entity_id: cohort.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( adjusted_days_homeless.display_as_editable?(editor, cohort_client) ).to be true
    end
    it 'display_as_editable? should return false if cohorts have been assigned, but the column is in another cohort' do
      GrdaWarehouse::UserViewableEntity.create(user_id: editor.id, entity_id: cohort_2.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( adjusted_days_homeless.display_as_editable?(editor, cohort_client) ).to be_falsey
    end
    it 'user should have access to assigned cohorts' do
      GrdaWarehouse::UserViewableEntity.create(user_id: editor.id, entity_id: cohort.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( GrdaWarehouse::Cohort.viewable_by(editor).where(id: cohort.id).exists? ).to be true
    end
    it 'user should not have access to other cohorts' do
      GrdaWarehouse::UserViewableEntity.create(user_id: editor.id, entity_id: cohort_2.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( GrdaWarehouse::Cohort.viewable_by(editor).where(id: cohort.id).exists? ).to be_falsey
    end
  end

  describe 'when a user with a cohort viewer role accesses a cohort column' do
    it 'display_as_editable? should always return false' do
      expect( adjusted_days_homeless.display_as_editable?(viewer, cohort_client) ).to be_falsey
    end
    it 'display_as_editable? should always return false, even if a cohort is assigned' do
      GrdaWarehouse::UserViewableEntity.create(user_id: viewer.id, entity_id: cohort.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( adjusted_days_homeless.display_as_editable?(viewer, cohort_client) ).to be_falsey
    end
    it 'display_as_editable? should always return false, even if another cohort is assigned' do
      GrdaWarehouse::UserViewableEntity.create(user_id: viewer.id, entity_id: cohort_2.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( adjusted_days_homeless.display_as_editable?(viewer, cohort_client) ).to be_falsey
    end
    it 'user should have access to assigned cohorts' do
      GrdaWarehouse::UserViewableEntity.create(user_id: viewer.id, entity_id: cohort.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( GrdaWarehouse::Cohort.viewable_by(viewer).where(id: cohort.id).exists? ).to be true
    end
    it 'user should not have access to other cohorts' do
      GrdaWarehouse::UserViewableEntity.create(user_id: viewer.id, entity_id: cohort_2.id, entity_type: GrdaWarehouse::Cohort.name)
      expect( GrdaWarehouse::Cohort.viewable_by(viewer).where(id: cohort.id).exists? ).to be_falsey
    end
  end

end