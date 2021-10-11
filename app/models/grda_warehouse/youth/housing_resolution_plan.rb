###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class HousingResolutionPlan < GrdaWarehouse::Youth::Base
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :housing_resolution_plans, optional: true
    belongs_to :user, optional: true
    has_many :youth_intakes, through: :client

    def yes_no
      [
        'Yes',
        'No',
      ]
    end

    def resolutions
      [
        'Return to an existing, safe living arrangement (with family, friends, or community members)',
        'Return to their own safe residence (where they legally lease or own the residence)',
        'Find a new, safe living arrangement (with family, friends, or community members)',
        'Find a new, safe living arrangement in a residence of their own (where they are signing a new lease)',
        'Relocate to to a safe place out of state with access to the supports needed to sustain housing',
      ]
    end

    def points_in_time
      [
        'Prevention: YYA is unstably housed, but not yet requesting entry into the homelessness system',
        'Diversion: YYA is requesting entry into the homelessness system',
        'Rapid exit: the YYA is in the homelessness system and exploring exit options',
      ]
    end

    def possible_crisis_causes
      [
        'Conflict at home',
        'Violence, abuse, safety issue in housing situation',
        'Eviction',
        'Doubled-up and must leave',
        'Sudden loss of income',
        'Sudden increase in living costs',
        'Rental and/or utilities arrears',
        'Other',
      ]
    end

    def factor_score
      [
        '1 - In Crisis',
        '2 - Vulnerable',
        '3 - Stable',
        '4 - Safe',
        '5 - Thriving',
      ]
    end
  end
end
