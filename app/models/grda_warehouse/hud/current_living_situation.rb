###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class CurrentLivingSituation < Base
    include HudSharedScopes
    include ::HMIS::Structure::CurrentLivingSituation
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :CurrentLivingSituation
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :current_living_situations, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_current_living_situations
    has_one :client, through: :enrollment, inverse_of: :current_living_situations
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source

    scope :between, ->(start_date:, end_date:) do
      where(arel_table[:InformationDate].between(start_date..end_date))
    end

  end
end
