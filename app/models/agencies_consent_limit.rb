###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AgenciesConsentLimit < ApplicationRecord
  belongs_to :agency
  belongs_to :consent_limit
end