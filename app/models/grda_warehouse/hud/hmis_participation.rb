###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Hud
  class HmisParticipation < Base
    include HudSharedScopes
    include ::HmisStructure::HmisParticipation
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :HMISParticipation
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :hmis_participations, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :hmis_participations, optional: true
    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :hmis_participations, optional: true
    belongs_to :data_source, optional: true

    scope :within_range, ->(range) do
      start_date = arel_table[:HMISParticipationStatusStartDate]
      end_date = arel_table[:HMISParticipationStatusEndDate]
      where(
        end_date.gteq(range.first).or(end_date.eq(nil)).
        and(start_date.lteq(range.last).or(start_date.eq(nil))),
      )
    end
  end
end
