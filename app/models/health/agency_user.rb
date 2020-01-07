###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class AgencyUser < HealthBase

    validates_presence_of :agency_id
    validates_presence_of :user_id

    belongs_to :agency, class_name: 'Health::Agency', foreign_key: 'agency_id'
    belongs_to :user

  end
end