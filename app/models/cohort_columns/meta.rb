###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Meta < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :meta
    attribute :title, String, lazy: true, default: _('Alerts')

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
      comments += "No homeless service in #{@cohort.days_of_inactivity} days\r\n" if inactive
      comments += "Client ineligible\r\n" if cohort_client.ineligible?
      comments
    end

    def value(cohort_client) # OK
      html = ''
      html += content_tag(:i, ' ', class: 'icon-warning warning') if inactive
      html += content_tag(:i, ' ', class: 'icon-notification warning') if cohort_client.ineligible?
      html
    end

    def text_value(_cohort_client)
      comments
    end

    def last_activity
      cohort_client.client.processed_service_history&.last_homeless_date
    end

    def inactive
      if cohort.days_of_inactivity && last_activity
        (Date.current - cohort.days_of_inactivity.days) > last_activity.to_date
      else
        true
      end
    end

    def inactivity_class
      ''
      # if inactive
      #   'homeless_inactive'
      # else
      #   ''
      # end
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

    def display_for(_user)
      display_read_only
    end

    def display_read_only(_user)
      value(cohort_client)
    end
  end
end
