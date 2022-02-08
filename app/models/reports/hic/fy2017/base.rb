###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    def has_options?
      false
    end

    def results_path
      reports_hic_export_path(version: 'fy2017')
    end
  end
end
