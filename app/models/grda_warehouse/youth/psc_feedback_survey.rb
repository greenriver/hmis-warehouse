###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Youth
  class PscFeedbackSurvey < GrdaWarehouse::Youth::Base
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :psc_feedback_surveys
    belongs_to :user, optional: true
    has_many :youth_intakes, through: :client

    def ratings
      [
        'Strongly Disagree',
        'Disgree',
        'Neither Agree or Disagree',
        'Agree',
        'Strongly Agree',
      ]
    end
  end
end
