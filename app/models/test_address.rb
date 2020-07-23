###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This facilitates unit testing
class TestAddress < ApplicationRecord
  belongs_to :test_person
end
