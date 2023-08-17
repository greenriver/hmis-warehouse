###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    # hide previous declaration of :importable, we'll use this one
    replace_scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
