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

    def anonymous?
      user_id.nil? && (whodunnit.blank? || whodunnit == 'unauthenticated')
    end

    def changes_with_computed_fallback
      changeset.presence || computed_changeset
    end

    protected

    # Extracted this method from the controller. It appears to be a fallback for old versions didn't include changes
    def computed_changeset
      version = self
      changed = {}

      current = version.reify
      return changed unless current

      if current.present? && version.event != 'destroy'
        if version.previous.present? && version.previous.object.present?
          previous = version.previous.reify
          changed_attr = (current.attributes.to_a - previous.attributes.to_a).map(&:first)
          changed_attr.each do |name|
            changed[name] = [previous[name], current[name]]
          end
        else
          # A create - so, all attributes are new
          current.attributes.to_a.each do |name|
            changed[name] = [nil, current[name]]
          end
        end
        # TODO: cache computed change
        # copy_of_changed = changed.clone # Serialize can be in place, so we clone to avoid stepping on the changed map
        # serializer = PaperTrail::AttributeSerializers::ObjectChangesAttribute.new(current.class)
        # serializer.serialize(copy_of_changed)

        # version.object_changes = copy_of_changed
        # version.save`
      elsif current.present?
        # Describe a destroy as setting all attributes to nil
        current.attributes.map(&:first).each do |name|
          changed[name] = [current[name], nil]
        end
      end
      changed
    end
  end
end
