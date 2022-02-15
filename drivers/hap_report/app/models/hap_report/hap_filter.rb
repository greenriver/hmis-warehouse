###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport
  class HapFilter < ::Filters::FilterBase
    validates_presence_of :start_date, :end_date, :project_ids
  end
end
