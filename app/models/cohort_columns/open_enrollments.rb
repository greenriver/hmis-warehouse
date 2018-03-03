module CohortColumns
  class OpenEnrollments < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :open_enrollments
    attribute :title, String, lazy: true, default: 'Open Residential Enrollments'

    def default_input_type
      :enrollment_tag
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
  end
end
