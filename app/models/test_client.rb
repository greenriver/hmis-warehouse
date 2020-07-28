###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This facilitates unit testing
class TestClient < ApplicationRecord
  include PIIAttributeSupport
  attr_pii :FirstName
end
