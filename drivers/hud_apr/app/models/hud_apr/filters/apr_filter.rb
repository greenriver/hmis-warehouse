###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Filters
  class AprFilter < ::Filters::FilterBase
    validates_presence_of :coc_codes
    validate do
      errors.add(:project_ids, 'or project groups must be specified') if project_ids.blank? && project_group_ids.blank?
    end

    # FilterBase defines semantics for coc_codes vs coc_code which this disables
    def effective_project_ids_from_coc_codes
      []
    end
  end
end
