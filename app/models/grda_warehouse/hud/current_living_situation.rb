###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class CurrentLivingSituation < Base
    include HudSharedScopes
    include ::HMIS::Structure::CurrentLivingSituation

    self.table_name = :CurrentLivingSituation

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :current_living_situation, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_current_living_situations
    has_one :client, through: :enrollment, inverse_of: :current_living_situations
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source

  end
end
