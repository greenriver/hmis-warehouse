# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Common paper trail version behavior shared across app and health database records
# Note: warehouse records use a different version table/model
module GrPaperTrailVersionBehavior
  extend ActiveSupport::Concern
  include PaperTrail::VersionConcern

  included do
    scope :for_users, -> {
      where(item_type: [User.sti_name, Hmis::User.sti_name])
    }

    scope :anonymous, -> {
      where(whodunnit: ['unauthenticated', nil], user_id: nil)
    }

    # Filters versions where object_changes includes any combination of the specified fields
    scope :matching_object_change_fields, ->(*fields) {
      raise ArgumentError, 'Fields expected' if fields.blank?

      sql = "ARRAY(SELECT DISTINCT (REGEXP_MATCHES(object_changes, '^([a-z0-9_:]+):', 'gm'))[1]) <@ ARRAY[?]::text[]"
      where(sql, fields)
    }
  end

  def anonymous?
    user_id.nil? && (whodunnit.blank? || whodunnit == 'unauthenticated')
  end

  def changes_with_computed_fallback
    changeset.presence || computed_changeset.presence
  end

  # When impersonating a user, whodunnit is recorded as "<true_user> as <current_user>"
  # * seems on newer records we record the true user as version.user_id
  WHODUNNIT_IMPERSONATOR_PATTERN = /^(\d+) as (\d+)$/

  def clean_user_id
    return if whodunnit.blank?
    return whodunnit if whodunnit&.match?(/\A\d+\z/)

    match = WHODUNNIT_IMPERSONATOR_PATTERN.match(whodunnit)
    match[2] if match
  end

  def clean_true_user_id
    return user_id if user_id
    return if whodunnit.blank?

    match = WHODUNNIT_IMPERSONATOR_PATTERN.match(whodunnit)
    match[1] if match
  end

  protected

  # Extracted this method from the controller. It appears to be a fallback for old versions didn't include changes
  # * Is this still needed?
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
