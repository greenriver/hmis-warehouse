###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class CeParticipation < Base
    include HudSharedScopes
    include ::HmisStructure::CeParticipation
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :CEParticipation
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :ce_participations, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :ce_participations, optional: true
    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :ce_participations, optional: true
    belongs_to :data_source, optional: true

    scope :within_range, ->(range) do
      start_date = arel_table[:CEParticipationStatusStartDate]
      end_date = arel_table[:CEParticipationStatusEndDate]
      where(
        end_date.gteq(range.first).or(end_date.eq(nil)).
        and(start_date.lteq(range.last).or(start_date.eq(nil))),
      )
    end
  end
end
