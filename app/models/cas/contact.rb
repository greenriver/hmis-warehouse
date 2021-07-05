###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cas
  class Contact < CasBase
    belongs_to :user, optional: true
  end
end
