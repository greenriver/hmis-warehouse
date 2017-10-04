module HudSharedScopes
  extend ActiveSupport::Concern
  included do
    scope :modified_within_range, -> (range:, include_deleted: false) do
      updated_within_range = arel_table[:DateUpdated].gteq(range.first).
        and(arel_table[:DateUpdated].lteq(range.last))
      created_within_range = arel_table[:DateCreated].gteq(range.first).
        and(arel_table[:DateCreated].lteq(range.last))
      deleted_within_range = arel_table[:DateDeleted].gteq(range.first).
        and(arel_table[:DateDeleted].lteq(range.last))
      if include_deleted
        where(updated_within_range.or(created_within_range).or(deleted_within_range))
      else
        where(updated_within_range.or(created_within_range))
      end
    end
  end
end