###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class AgenciesConsentLimit < ActiveRecord::Base
  belongs_to :agency
  belongs_to :consent_limit
end