###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AgenciesConsentLimit < ApplicationRecord
  belongs_to :agency, optional: true
  belongs_to :consent_limit, optional: true
end
