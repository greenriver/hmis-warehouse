###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrPaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern
    include GrPaperTrailConcern

    scope :for_users, -> {
      where(item_type: [User.sti_name, Hmis::User.sti_name])
    }

    scope :anonymous, -> {
      where(whodunnit: ['unauthenticated', nil])
    }

    # ensure the object_changes matches item count
    scope :with_change_count, -> (min_count, max_count=nil) {
      max_count ||= min_count

      return where(object_changes: nil) if max_count == 0

      # extra line due to split on yaml
      min_count += 1
      max_count += 1
      where("ARRAY_LENGTH(REGEXP_SPLIT_TO_ARRAY(object_changes, E':\\n-'), 1) BETWEEN ? AND ?", min_count, max_count)
    }

    scope :only_certain_fields, ->(*allowed_keys) {
      where(%{
        ARRAY(
          SELECT DISTINCT REGEXP_MATCHES(object_changes, '([^:]+):', 'g')
        ) <@ ARRAY[?]::text[]
      }, allowed_keys)
      where(%{

      }, allowed_keys)
    }

    # Filters versions where object_changes includes any combination of the specified fields
    scope :matching_object_change_fields, ->(*fields) {
      return none if fields.blank?

      sql = "ARRAY(SELECT DISTINCT (REGEXP_MATCHES(object_changes, '^([a-z0-9_:]+):', 'gm'))[1]) <@ ARRAY[?]::text[]"
      where(sql, fields)
    }


    # versions.object_changes_has_all_keys(:updated_at, :last_sign_in_at)
    scope :object_changes_has_all_keys, ->(*keys) {
      versions = arel_table
      conditions = keys.map do |key|
        versions[:object_changes].matches("%#{key}:\n-%", nil, true) # case-sensitive match
      end
      where(conditions.reduce(&:and))
    }

    scope :successful_authentications, -> {
      anonymous.for_users.
        object_changes_has_all_keys('current_sign_in_at', 'last_sign_in_at', 'sign_in_count', 'updated_at').
        with_change_count(4, 6)
    }

    scope :user_failed_attempts, -> {
      anonymous.for_users.
        object_changes_has_all_keys('failed_attempts', 'updated_at').
        with_change_count(2, 2)
    }

    #["failed_attempts", "updated_at"]

    def anonymous?
      user_id.nil? && (whodunnit.blank? || whodunnit == 'unauthenticated')
    end

  end
end
