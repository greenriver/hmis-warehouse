###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class Version < GrdaWarehouseBase
    include PaperTrail::VersionConcern

    belongs_to :hmis_client, class_name: 'Hmis::Hud::Client', foreign_key: :client_id, optional: true
    belongs_to :hmis_project, class_name: 'Hmis::Hud::Project', foreign_key: :project_id, optional: true

    # Filters versions where object_changes includes any combination of the specified fields
    scope :matching_object_change_fields, ->(*fields) {
      raise ArgumentError, 'Fields expected' if fields.blank?

      sql = "ARRAY(SELECT DISTINCT (REGEXP_MATCHES(object_changes, '^([a-z0-9_:]+):', 'gm'))[1]) <@ ARRAY[?]::text[]"
      where(sql, fields)
    }

    # overlay object changes onto object
    def object_with_changes
      # create events have object_changes and a nil object
      result = object&.dup || {}
      result.merge!(object_changes.transform_values(&:last)) if object_changes.present?
      result
    end

    def changes_with_computed_fallback
      changeset.presence || computed_changeset.presence
    end

    def anonymous?
      user_id.nil? && (whodunnit.blank? || whodunnit == 'unauthenticated')
    end

    def clean_user_id
      [
        # User user_id if available
        user_id,
        # Otherwise use whodunnit
        whodunnit&.match?(/^\d+$/) ? whodunnit : nil,
        whodunnit&.match?(whodunnit_impersonator_pattern) ? whodunnit.sub(whodunnit_impersonator_pattern, '\2') : nil,
      ].find(&:present?)
    end

    def clean_true_user_id
      [
        # Don't return if not impersonating (i.e. user == true_user), use true_user_id if available
        user_id != true_user_id ? true_user_id : nil,
        # Use whodunnit if not
        whodunnit&.match?(whodunnit_impersonator_pattern) ? whodunnit.sub(whodunnit_impersonator_pattern, '\1') : nil,
      ].find(&:present?)
    end

    def whodunnit_impersonator_pattern
      # When impersonating a user, whodunnit is recorded as "<true_user> as <current_user>"
      /^(\d+) as (\d+)$/
    end

    # Fallback for old versions that didn't include changes
    protected def computed_changeset
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
          current.attributes.each do |name, value|
            changed[name] = [nil, value]
          end
        end
      elsif current.present?
        # Describe a destroy as setting all attributes to nil
        current.attributes.each do |name, value|
          changed[name] = [value, nil]
        end
      end
      changed
    end
  end
end
