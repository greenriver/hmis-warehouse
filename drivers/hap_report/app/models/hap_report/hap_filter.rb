###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HapReport
  class HapFilter < ::Filters::FilterBase
    validates_presence_of :start_date, :end_date, :project_ids
  end
end
