###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientHelper
  def enrolled(client, window_only: true)
    enrollments = client.scope_for_ongoing_residential_enrollments
    enrollments = enrollments.visible_in_window_to(current_user) if window_only
    enrollments.distinct.pluck(:project_type).map do |project_type|
      if project_type == 13
        [project_type, 'RRH']
      else
        [project_type, HUD.project_type_brief(project_type)]
      end
    end.map do |project_type, text|
      content_tag(:div, class: "enrollment__project_type client__service_type_#{project_type}") do
        content_tag(:em, class: 'service-type__program-type') do
          text
        end
      end
    end.join(' ').html_safe
  end
end
