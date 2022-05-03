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
  end
end
