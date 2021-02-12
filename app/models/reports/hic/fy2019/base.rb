###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports::Hic::Fy2019
  class Base < Report
    def self.report_name
      'HIC - FY 2019'
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

    def options?
      false
    end

    def results_path
      reports_hic_export_path(version: 'fy2019')
    end
  end
end
