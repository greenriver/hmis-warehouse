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
      comments = ''
      if inactive
        comments += "No homeless service in #{@cohort.days_of_inactivity} days\r\n"
      end
      if cohort_client.ineligible?
        comments += "Client ineligible\r\n"
      end
      return comments
    end

    def value(cohort_client) # OK
      html = ''
      if inactive
        html += content_tag(:i, ' ', class: "icon-warning warning")
      end
      if cohort_client.ineligible?
        html += content_tag(:i, ' ', class: "icon-notification warning")
      end
      return html
    end

    def text_value cohort_client
      comments
    end

    def last_activity
      cohort_client.client.processed_service_history&.last_homeless_date
    end

    def inactive
      if cohort.days_of_inactivity && last_activity
        (Date.today - cohort.days_of_inactivity.days) > last_activity.to_date
      else
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
        client_id: cohort_client&.client&.id,
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
