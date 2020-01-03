###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class VerificationSource::Disability < GrdaWarehouse::VerificationSource
    self.table_name = :verification_sources


    def title
      'Disability Verification'
    end
  end
end