###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Filters
  class DqFilter < ::Filters::FilterBase
    # FilterBase defines semantics for coc_codes vs coc_code which this disables
    def effective_project_ids_from_coc_codes
      []
    end

    def default_project_type_codes
      []
    end
  end
end
