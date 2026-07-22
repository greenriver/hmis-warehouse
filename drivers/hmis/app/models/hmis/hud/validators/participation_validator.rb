###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared overlap validation for HMIS and CE Participation date ranges.
class Hmis::Hud::Validators::ParticipationValidator < Hmis::Hud::Validators::BaseValidator
  OVERLAP_MESSAGE = 'Participation date range overlaps another participation period.'

  class << self
    # Finds a non-deleted participation for the same project and data source
    # whose inclusive date range overlaps the proposed range.
    def conflicting_record(record)
      start_date = record.public_send(start_date_attribute)
      return unless start_date && record.data_source_id && record.ProjectID

      # The model's default scope excludes soft-deleted records.
      relation = record.class.where(
        data_source_id: record.data_source_id,
        ProjectID: record.ProjectID,
      )
      # An update may overlap its current persisted values, so exclude itself.
      relation = relation.where.not(id: record.id) if record.persisted?

      table = record.class.arel_table
      end_date = record.public_send(end_date_attribute)
      # A blank proposed end date is unbounded and therefore has no upper limit.
      relation = relation.where(table[start_date_attribute].lteq(end_date)) if end_date
      # A blank existing end date is also unbounded.
      relation.
        where(table[end_date_attribute].eq(nil).or(table[end_date_attribute].gteq(start_date))).
        first
    end

    # Mark both date fields so the form identifies the full invalid range.
    def overlap_error_attributes
      [start_date_attribute, end_date_attribute]
    end

    # Each concrete validator supplies its model-specific date columns.
    def start_date_attribute
      const_get(:START_DATE_ATTRIBUTE)
    end

    def end_date_attribute
      const_get(:END_DATE_ATTRIBUTE)
    end
  end

  # Blocks every create or update that would leave an overlapping range.
  def validate(record)
    return if skip_all_validations?(record)
    return unless self.class.conflicting_record(record)

    self.class.overlap_error_attributes.each do |attribute|
      record.errors.add(
        attribute,
        :invalid,
        message: OVERLAP_MESSAGE,
        full_message: OVERLAP_MESSAGE,
      )
    end
  end
end
