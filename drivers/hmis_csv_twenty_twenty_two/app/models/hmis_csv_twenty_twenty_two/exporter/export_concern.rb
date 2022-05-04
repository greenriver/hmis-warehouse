###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter::ExportConcern
  extend ActiveSupport::Concern
  included do
    include ArelHelper

    def self.simple_override(row, hud_field:, override_field:, default_value: nil)
      row[hud_field] ||= default_value if default_value.present?
      return row if row.send(override_field).blank?

      row[hud_field] = row.send(override_field)
      row
    end

    def self.replace_blank(row, hud_field:, default_value:)
      row[hud_field] ||= default_value
      row
    end

    def self.note_involved_user_ids(scope:, export:)
      u_t = GrdaWarehouse::Hud::User.arel_table

      # Note user_ids
      export.user_ids ||= Set.new
      export.user_ids += scope.distinct.joins(:user).pluck(u_t[:id])
    end

    def self.enrollment_exists_for_model(enrollment_scope, hmis_class)
      enrollment_scope.where(
        e_t[:PersonalID].eq(hmis_class.arel_table[:PersonalID]).
        and(e_t[:EnrollmentID].eq(hmis_class.arel_table[:EnrollmentID])).
        and(e_t[:data_source_id].eq(hmis_class.arel_table[:data_source_id])),
      ).arel.exists
    end

    def self.project_exists_for_model(project_scope, hmis_class)
      project_scope.where(
        p_t[:ProjectID].eq(hmis_class.arel_table[:ProjectID]).
        and(p_t[:data_source_id].eq(hmis_class.arel_table[:data_source_id])),
      ).arel.exists
    end

    def enrollment_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.id
      else
        row.enrollment&.id
      end

      id || 'Unknown'
    end

    def project_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.project_with_deleted&.id
      else
        row.enrollment&.project&.id
      end

      id || 'Unknown'
    end

    def personal_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.client_with_deleted&.id
      else
        row.enrollment&.client&.id
      end

      id || 'Unknown'
    end
  end
end
