module CohortColumns
  class OpenEnrollments < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :open_enrollments
    attribute :title, String, lazy: true, default: 'Open Residential Enrollments'
    
    def column_editable?
      false
    end

    def default_input_type
      :enrollment_tag
    end

    def renderer
      'html'
    end

    def value(cohort_client)
      cohort_client.client.
        service_history_enrollments.ongoing.
        distinct.residential.
        pluck(:project_type).map do |project_type|
          if project_type == 13
            [project_type, 'RRH']
          else
            [project_type, HUD.project_type_brief(project_type)]
          end
        end
     
    end

    def display_for user
      display_read_only(user)
    end

    def display_read_only user
      value(cohort_client).map do |project_type, text|
        content_tag(:div, class: "enrollment__project_type client__service_type_#{project_type}") do
          content_tag(:em, class: 'service-type__program-type') do
            text
          end
        end
      end.join(' ').html_safe
    end
  end
end
