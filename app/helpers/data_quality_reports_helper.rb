###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Leaves drilldown links off the report page when DataQualityReportsController#support would refuse them.
module DataQualityReportsHelper
  def dq_support_path(support_path)
    support_path if can_view_dq_drilldowns?
  end

  # Empty when drilldowns are refused; the chart scripts skip click-through on an empty URL.
  def dq_support_url(support_path, params)
    path = dq_support_path(support_path)
    path ? polymorphic_path(path, params) : ''
  end

  # Renders the block's content without a link when drilldowns are refused.
  def dq_support_link_to(support_path, params, **html_options, &block)
    path = dq_support_path(support_path)
    return capture(&block) unless path

    link_to(polymorphic_path(path, params), **html_options, &block)
  end
end
