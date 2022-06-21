###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::ProjectDataQualityReports::VersionFour::Support
  extend ActiveSupport::Concern
  include ActionView::Helpers
  include ActionView::Context
  included do
    def support_for(options)
      return {} unless options[:method].present?
      return {} unless support_method_whitelist.detect { |m| m == options[:method].to_sym }

      support_method = "#{options[:method]}_support"
      send(support_method, options)
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
        :service_after_exit_date,
        :move_in_date_after_threshold,
        :household_type_mismatch,
        :enrollments_with_no_service,
        :project_completeness,
        :average_time_to_enter,
        :average_time_to_exit,
        :enrolled_length_of_stay,
        :ph_destinations,
        :retained_income,
        :no_income,
      ]
    end

    def enrolled_clients_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.pluck(*enrollment_support_columns.values),
        title: 'Enrolled Clients',
      }
    end

    def enrolled_households_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_household_heads.pluck(*enrollment_support_columns.values),
        title: 'Enrolled Households',
      }
    end

    def active_clients_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: active_clients.pluck(*enrollment_support_columns.values),
        title: 'Active Clients',
      }
    end

    def active_households_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: active_households.pluck(*enrollment_support_columns.values),
        title: 'Active Households',
      }
    end

    def entering_clients_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: entering_clients.pluck(*enrollment_support_columns.values),
        title: 'Entering Clients',
      }
    end

    def entering_households_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: entering_households.pluck(*enrollment_support_columns.values),
        title: 'Entering Households',
      }
    end

    def exiting_clients_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: exiting_clients.pluck(*enrollment_support_columns.values),
        title: 'Exiting Clients',
      }
    end

    def exiting_households_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: exiting_households.pluck(*enrollment_support_columns.values),
        title: 'Exiting Households',
      }
    end

    def dob_after_entry_support(_options)
      {
        headers: client_support_columns.keys,
        counts: enrolled_clients.where(dob_after_entry_date: true).
          pluck(*client_support_columns.values),
        title: 'DOB After Entry',
      }
    end

    def final_month_service_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.where(service_within_last_30_days: false).
          pluck(*enrollment_support_columns.values),
        title: 'No Service in Final Month',
      }
    end

    def service_after_exit_date_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: exiting_clients.where(service_after_exit: true).
          pluck(*enrollment_support_columns.values),
        title: 'Service After Exit',
      }
    end

    def move_in_date_after_threshold_support(_options)
      {
        headers: ph_support_columns.keys,
        counts: move_in_date_above_threshold.pluck(*ph_support_columns.values),
        title: 'Excessive Time Prior to Move-in Date',
      }
    end

    def household_type_mismatch_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.where(incorrect_household_type: true).
          pluck(*enrollment_support_columns.values),
        title: 'Incorrect Household Type',
      }
    end

    def enrollments_with_no_service_support(_options)
      {
        headers: enrollment_support_columns.keys,
        counts: enrolled_clients.where(days_of_service: 0).
          pluck(*enrollment_support_columns.values),
        title: 'No Service',
      }
    end

    def project_completeness_support(options)
      key = options[:column].to_sym
      metric = completeness_metrics[key]
      measure = options[:metric].to_sym
      title = "#{metric[:label]} #{options[:metric].humanize}"
      denominator = metric[:denominator]
      count_scope = send(denominator).where("#{key}_#{measure}" => true)
      count_scope = count_scope.where(project_id: options[:selected_project_id].to_i) if options[:selected_project_id]&.to_i&.to_s == options[:selected_project_id]
      support = {
        headers: completeness_support_columns(key).keys,
        counts: count_scope.pluck(*completeness_support_columns(key).values),
        title: title,
      }
      support[:description] = ssn_warning_html if key == :ssn
      support[:description] = dob_warning_html if key == :dob
      support
    end

    def ssn_warning_html
      content_tag(:div, class: 'alert alert-info display-block') do
        [
          content_tag(:h3, 'Please Note'),
          content_tag(:p, 'SSNs will appear as missing if they meet any of the following rules:', class: 'w-100'),
          content_tag(:ul) do
            ::HUD.describe_valid_social_rules.map do |rule|
              content_tag(:li, rule)
            end.join.html_safe
          end,
        ].join.html_safe
      end
    end

    def dob_warning_html
      content_tag(:div, class: 'alert alert-info display-block') do
        [
          content_tag(:h3, 'Please Note'),
          content_tag(:p, 'DOBs will appear as missing if they meet any of the following rules:', class: 'w-100'),
          content_tag(:ul) do
            ::HUD.describe_valid_dob_rules.map do |rule|
              content_tag(:li, rule)
            end.join.html_safe
          end,
        ].join.html_safe
      end
    end

    def average_time_to_enter_support(options)
      enrollment_scope = enrolled_clients
      enrollment_scope = enrollment_scope.where(project_id: options[:selected_project_id].to_i) if options[:selected_project_id]&.to_i&.to_s == options[:selected_project_id]
      {
        headers: timeliness_support_columns.keys,
        counts: enrollment_scope.pluck(*timeliness_support_columns.values),
        title: 'Time to Enter Entry Date',
      }
    end

    def average_time_to_exit_support(options)
      enrollment_scope = exiting_clients
      enrollment_scope = enrollment_scope.where(project_id: options[:selected_project_id].to_i) if options[:selected_project_id]&.to_i&.to_s == options[:selected_project_id]
      {
        headers: timeliness_support_columns.keys,
        counts: enrollment_scope.pluck(*timeliness_support_columns.values),
        title: 'Time to Enter Exit Date',
      }
    end

    def enrolled_length_of_stay_support(options)
      bucket = self.class.length_of_stay_buckets.values.detect { |r| r.to_s == options[:metric] }
      return {} unless bucket.present?

      enrollment_scope = enrolled_clients.where(days_of_service: bucket)
      enrollment_scope = enrollment_scope.where(project_id: options[:selected_project_id].to_i) if options[:selected_project_id]&.to_i&.to_s == options[:selected_project_id]
      {
        headers: enrollment_support_columns.keys,
        counts: enrollment_scope.pluck(*enrollment_support_columns.values),
        title: 'Length of Stay',
      }
    end

    def ph_destinations_support(options)
      enrollment_scope = exiting_clients.where(destination_id: HUD.permanent_destinations)
      enrollment_scope = enrollment_scope.where(project_id: options[:selected_project_id].to_i) if options[:selected_project_id]&.to_i&.to_s == options[:selected_project_id]
      {
        headers: enrollment_support_columns.keys,
        counts: enrollment_scope.pluck(*enrollment_support_columns.values),
        title: 'Permanent Destination',
      }
    end

    def retained_income_support(options)
      included_clients = enrolled_clients.where.not(income_at_later_date_overall: nil)
      a_t = Reporting::DataQualityReports::Enrollment.arel_table
      where = case options[:metric].to_sym
      when :earned_income
        a_t[:income_at_later_date_earned].gteq(a_t[:income_at_penultimate_earned])
      when :non_employment_cash_income
        a_t[:income_at_later_date_non_employment_cash].gteq(a_t[:income_at_penultimate_non_employment_cash])
      when :overall_income
        a_t[:income_at_later_date_overall].gteq(a_t[:income_at_penultimate_overall])
      when :earned_income_20
        a_t[:income_at_later_date_earned].gt(a_t[:income_at_penultimate_earned] * Arel::Nodes::SqlLiteral.new('1.20'))
      when :non_employment_cash_income_20
        a_t[:income_at_later_date_non_employment_cash].gt(a_t[:income_at_penultimate_non_employment_cash] * Arel::Nodes::SqlLiteral.new('1.20'))
      when :overall_income_20
        a_t[:income_at_later_date_overall].gt(a_t[:income_at_penultimate_overall] * Arel::Nodes::SqlLiteral.new('1.20'))
      end
      {
        headers: income_support_columns.keys,
        counts: included_clients.where(where).pluck(*income_support_columns.values),
        title: 'Income',
      }
    end

    def no_income_support(options)
      included_clients = enrollments.enrolled.adult_or_head_of_household

      ids = case options[:metric].to_sym
      when :no_earned_income
        clients_with_no_income[:earned]
      when :no_non_employment_cash_income
        clients_with_no_income[:non_employment_cash]
      when :no_income_overall
        clients_with_no_income[:overall]
      end
      {
        headers: no_income_support_columns.keys,
        counts: included_clients.where(id: ids.to_a).pluck(*no_income_support_columns.values),
        title: 'No Income',
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
        'Project ID' => :project_id,
        'Most Recent Service' => :most_recent_service_within_range,
        'Days of Service' => :days_of_service,
        'Destination' => :destination_id,
      }
    end

    def ph_support_columns
      @ph_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Entry Date' => :entry_date,
        'Move-in Date' => :move_in_date,
        'Days to Move-in' => :days_to_move_in_date,
        'Exit Date' => :exit_date,
        'Project' => :project_name,
        'Project ID' => :project_id,
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
        'Gender 2022' => :gender_multi,
        'Entry Date' => :entry_date,
        'Project' => :project_name,
        'Project ID' => :project_id,
      }
    end

    def completeness_support_columns(column)
      @completeness_support_columns ||= client_support_columns
      case column
      when :veteran
        @completeness_support_columns['Veteran Status'] = :veteran_status
      when :dob
        @completeness_support_columns['DOB Quality'] = :dob_data_quality
      when :first_name, :last_name, :name
        @completeness_support_columns['Name Quality'] = :name_data_quality
      when :ssn
        @completeness_support_columns['SSN Quality'] = :ssn_data_quality
      when :destination
        @completeness_support_columns['Destination'] = :destination_id
      when :income_at_annual_assessment
        @completeness_support_columns['Annual Assessment Earned'] = :income_at_annual_earned
        @completeness_support_columns['Annual Assessment Non-Employment'] = :income_at_annual_non_employment_cash
        @completeness_support_columns['Annual Assessment Overall'] = :income_at_annual_overall
        @completeness_support_columns['Annual Assessment Response'] = :income_at_annual_response
      when :income_at_entry
        @completeness_support_columns['Entry Earned'] = :income_at_entry_earned
        @completeness_support_columns['Entry Non-Employment'] = :income_at_entry_non_employment_cash
        @completeness_support_columns['Entry Overall'] = :income_at_entry_overall
        @completeness_support_columns['Entry Response'] = :income_at_entry_response
      when :income_at_exit
        @completeness_support_columns['Exit Earned'] = :income_at_later_date_earned
        @completeness_support_columns['Exit Non-Employment'] = :income_at_later_date_non_employment_cash
        @completeness_support_columns['Exit Overall'] = :income_at_later_date_overall
        @completeness_support_columns['Exit Response'] = :income_at_later_date_response
      else
        @completeness_support_columns[completeness_metrics[column][:label]] = column
      end
      @completeness_support_columns
    end

    def income_support_columns
      @income_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Entry Date' => :entry_date,
        'Exit Date' => :exit_date,
        'Project' => :project_name,
        'Project ID' => :project_id,
        'Entry Earned' => :income_at_entry_earned,
        'Entry Non-Employment' => :income_at_entry_non_employment_cash,
        'Entry Overall' => :income_at_entry_overall,
        'Penultimate Earned' => :income_at_penultimate_earned,
        'Penultimate Non-Employment' => :income_at_penultimate_non_employment_cash,
        'Penultimate Overall' => :income_at_penultimate_overall,
        'Later Earned' => :income_at_later_date_earned,
        'Later Non-Employment' => :income_at_later_date_non_employment_cash,
        'Later Overall' => :income_at_later_date_overall,
      }
    end

    def no_income_support_columns
      @no_income_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Entry Date' => :entry_date,
        'Exit Date' => :exit_date,
        'Project' => :project_name,
        'Project ID' => :project_id,
        'Entry Response' => :income_at_entry_response,
        'Entry Earned' => :income_at_entry_earned,
        'Entry Non-Employment' => :income_at_entry_non_employment_cash,
        'Entry Overall' => :income_at_entry_overall,
        'Later Response' => :income_at_later_date_response,
        'Later Earned' => :income_at_later_date_earned,
        'Later Non-Employment' => :income_at_later_date_non_employment_cash,
        'Later Overall' => :income_at_later_date_overall,
      }
    end

    def timeliness_support_columns
      @timeliness_support_columns ||= {
        'Client ID' => :client_id,
        'First Name' => :first_name,
        'Last Name' => :last_name,
        'Entry Date' => :entry_date,
        'Entry Date Entered' => :enrollment_date_created,
        'Days to Enter' => :days_to_add_entry_date,
        'Exit Date' => :exit_date,
        'Exit Date Entered' => :exit_date_created,
        'Days to Exit' => :days_to_add_exit_date,
        'Project' => :project_name,
        'Project ID' => :project_id,
      }
    end
  end
end
