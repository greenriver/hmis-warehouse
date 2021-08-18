###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Filters
  class AprFilter < ::Filters::HudFilterBase
    validates_presence_of :coc_codes
    validate do
      errors.add(:project_ids, 'or project groups must be specified') if project_ids.blank? && project_group_ids.blank?
    end
  end
end
