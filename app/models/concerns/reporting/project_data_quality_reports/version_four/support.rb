module Reporting::ProjectDataQualityReports::VersionFour::Support
  extend ActiveSupport::Concern
  include ActionView::Helpers
  include ActionView::Context
  included do

    def support_for options
      return [] unless options[:method].present?
      return [] unless support_method_whitelist.detect{ |m| m == options[:method].to_sym }
      support_method = "#{options[:method]}_support"
      self.send(support_method, options)
      # :project_id,
      # :project_group_id,
      # :selected_project_id,
      # :method,
      # :title,
      # :layout,
    end

    def support_method_whitelist
      @support_method_whitelist ||= [
        :enrolled_clients,
        :enrolled_households,
        :active_clients,
        :active_households,
        :entering_clients,
        :entering_households,
        :exiting_clients,
        :exiting_households,
        :dob_after_entry,
        :final_month_service,
      ]
    end

    def enrolled_clients_support options
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.pluck(*enrollment_support_columns.values)
      }
    end

    def enrolled_households_support options
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_household_heads.pluck(*enrollment_support_columns.values)
      }
    end

    def active_clients_support options
      {
        headers: enrollment_support_columns.keys,
        counts: active_clients.pluck(*enrollment_support_columns.values)
      }
    end

    def active_households_support options
      {
        headers: enrollment_support_columns.keys,
        counts: active_households.pluck(*enrollment_support_columns.values)
      }
    end

    def entering_clients_support options
      {
        headers: enrollment_support_columns.keys,
        counts: entering_clients.pluck(*enrollment_support_columns.values)
      }
    end

    def entering_households_support options
      {
        headers: enrollment_support_columns.keys,
        counts: entering_households.pluck(*enrollment_support_columns.values)
      }
    end

    def exiting_clients_support options
      {
        headers: enrollment_support_columns.keys,
        counts: exiting_clients.pluck(*enrollment_support_columns.values)
      }
    end

    def exiting_households_support options
      {
        headers: enrollment_support_columns.keys,
        counts: exiting_households.pluck(*enrollment_support_columns.values)
      }
    end

    def dob_after_entry_support options
      {
        headers: client_support_columns.keys,
        counts: enrolled_clients.where(dob_after_entry_date: true).
          pluck(*client_support_columns.values)
      }
    end

    def final_month_service_support options
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.where(service_within_last_30_days: true).
          pluck(*enrollment_support_columns.values)
      }
    end

    def enrollment_support_columns
      @enrollment_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Entry Date' => :entry_date,
        'Exit Date' => :exit_date,
        'Project' => :project_name,
        'Most Recent Service' => :most_recent_service_within_range,
        'Destination' => :destination_id,
      }
    end

    def client_support_columns
      @client_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'DOB' => :dob,
        'SSN' => :ssn,
        'Gender' => :gender,
        'Entry Date' => :entry_date,
        'Project' => :project_name,
      }
    end

  end
end