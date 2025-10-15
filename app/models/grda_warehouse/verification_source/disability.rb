###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class VerificationSource::Disability < GrdaWarehouse::VerificationSource
    self.table_name = :verification_sources


    def title
      'Disability Verification'
    end
  end
end
