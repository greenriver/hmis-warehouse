###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module DataQualityReportsHelper
  # Renders the block as plain text when the user can't open the client-level support page.
  def dq_support_link_to(path_parts, params, html_options = {}, &block)
    return capture(&block) unless can_view_dq_support?

    link_to(polymorphic_path(path_parts, params), html_options, &block)
  end

  # Blank when the user can't open support, so chart click handlers have no URL to follow.
  def dq_support_url(path_parts, params)
    return '' unless can_view_dq_support?

    polymorphic_path(path_parts, params)
  end
end
