module CohortColumns
  class Meta < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :meta
    attribute :title, String, lazy: true, default: ''
    
    def column_editable?
      false
    end

    def default_input_type
      :read_only
    end

    def renderer
      'text'
    end

    def width
      75
    end

    def value(cohort_client)
      inactivity_warning = ''
      if inactive
        inactivity_warning = "No homeless service in over #{@cohort.days_of_inactivity} days #{cohort_client.id}"
      end
      inactivity_warning 
    end

    def last_activity
      cohort_client.client.service_history_services.homeless.maximum(:date)
    end

    def inactive
      @inactive ||= begin
        if Date.today - cohort.days_of_inactivity > last_activity 
          true
        else '' 
        end 
      rescue
        true
      end
    end

    def inactivity_class
      if inactive
        'homeless_inactive'
      else
        ''
      end
    end

    def metadata
      {
        activity: inactivity_class, 
        ineligible: cohort_client.ineligible?, 
        cohort_client_id: cohort_client.id, 
        client_id: cohort_client.client.id, 
        cohort_client_updated_at: cohort_client.updated_at.to_i, 
      }
    end

    def display_for user
      display_read_only
    end

    def display_read_only
      value(cohort_client)
    end
  end
end
