###
# Copyright Green River Data Group, Inc.
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
