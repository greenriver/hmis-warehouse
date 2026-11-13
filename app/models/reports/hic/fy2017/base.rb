###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Retired. This class exists solely so legacy `reports` rows still load via STI.
# The HIC is now produced by the LSA HIC (HudLsa::LsaHicsController).
module Reports::Hic::Fy2017
  class Base < Report
    def self.report_name
      'HIC - FY 2017'
    end

    def report_group_name
      'Housing Inventory Count (HIC)'
    end

    def continuum_name
      'Boston Continuum of Care'
    end

    def download_type
      nil
    end
  end
end
