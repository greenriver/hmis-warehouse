###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AgenciesConsentLimit < ApplicationRecord
  belongs_to :agency, optional: true
  belongs_to :consent_limit, optional: true
end
