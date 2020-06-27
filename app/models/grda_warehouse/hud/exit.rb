###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Exit < Base
    include HudSharedScopes
    include ::HMIS::Structure::Exit

    self.table_name = 'Exit'
    self.hud_key = :ExitID
    acts_as_paranoid column: :DateDeleted

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :exit
    belongs_to :data_source, inverse_of: :exits
    has_one :client, through: :enrollment, inverse_of: :exits
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_exits
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :exits, optional: true
    has_one :project, through: :enrollment
    has_one :destination_client, through: :enrollment

    scope :permanent, -> do
      where(Destination: ::HUD.permanent_destinations)
    end

    #################################
    # Standard Cohort Scopes
    scope :veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.veteran)
    end

    scope :non_veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.non_veteran)
    end

    scope :family, -> do
      joins(:project).merge(GrdaWarehouse::Hud::Project.family)
    end

    scope :individual, -> do
      joins(:project).merge(GrdaWarehouse::Hud::Project.individual)
    end

    # End Standard Cohort Scopes
    #################################

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end