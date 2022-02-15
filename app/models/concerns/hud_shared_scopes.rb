###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSharedScopes
  extend ActiveSupport::Concern
  included do
    scope :modified_within_range, ->(range:) do
      updated_within_range = arel_table[:DateUpdated].between(range)
      created_within_range = arel_table[:DateCreated].between(range)
      deleted_within_range = arel_table[:DateDeleted].between(range)
      where(updated_within_range.or(created_within_range).or(deleted_within_range))
    end

    scope :importable, -> do
      all
    end

    scope :hmis_source_visible_by, ->(user) do
      return none unless user.can_upload_hud_zips?
      return none unless GrdaWarehouse::DataSource.editable_by(user).source.exists?

      where(data_source_id: GrdaWarehouse::DataSource.editable_by(user).source.select(:id))
    end
  end
end
