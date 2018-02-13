module HudSharedScopes
  extend ActiveSupport::Concern
  included do
    scope :modified_within_range, -> (range:) do
      updated_within_range = arel_table[:DateUpdated].between(range)
      created_within_range = arel_table[:DateCreated].between(range)
      deleted_within_range = arel_table[:DateDeleted].between(range)
      where(updated_within_range.or(created_within_range).or(deleted_within_range))
    end
  end
end