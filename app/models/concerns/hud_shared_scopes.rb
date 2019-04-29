module HudSharedScopes
  extend ActiveSupport::Concern
  included do
    scope :modified_within_range, -> (range:) do
      updated_within_range = arel_table[:DateUpdated].between(range)
      created_within_range = arel_table[:DateCreated].between(range)
      deleted_within_range = arel_table[:DateDeleted].between(range)
      where(updated_within_range.or(created_within_range).or(deleted_within_range))
    end

    scope :hmis_source_visible_by, -> (user) do
      return current_scope if user.can_edit_anything_super_user?
      return none unless user.can_upload_hud_zips?
      return none unless GrdaWarehouse::DataSource.editable_by(user).source.exists?
      where(data_source_id: GrdaWarehouse::DataSource.editable_by(user).source.select(:id))
    end

    def hmis_source_visible_by? user
      return true if  user.can_edit_anything_super_user?
      return false unless user.can_upload_hud_zips?
      return false unless GrdaWarehouse::DataSource.editable_by(user).source.exists?
      self.class.hmis_source_visible_by(user).where(id: id).exists?
    end
  end
end