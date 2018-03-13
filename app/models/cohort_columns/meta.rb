module CohortColumns
  class Meta < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :meta
    attribute :title, String, lazy: true, default: 'Alerts'
    
    def column_editable?
      false
    end

    def default_input_type
      :read_only
    end

    def renderer
      'html'
    end

    def width
      0
    end

    def comments
      if inactive
        inactivity_warning = "No homeless service in #{@cohort.days_of_inactivity} days"
      end
    end

    def value(cohort_client)
      if inactive
        content_tag(:i, ' ', class: "icon-warning warning")
      end
    end

    def last_activity
      @last_activity ||= cohort_client.client.service_history_services.homeless.maximum(:date)
    end

    def inactive
      @inactive ||= begin
        Date.today - cohort.days_of_inactivity > last_activity.to_date
      rescue
        true
      end
    end

    def inactivity_class
      if inactive
        'homeless_inactive'
        ''
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
        last_activity: last_activity,
        inactive: inactive,
      }
    end

    def display_for user
      display_read_only
    end

    def display_read_only user
      value(cohort_client)
    end
  end
end
