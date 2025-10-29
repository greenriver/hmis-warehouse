###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class AlertDefinition < GrdaWarehouseBase
    VALID_CATEGORIES = [
      'system',
      'data_quality',
      'client_activity',
      'enrollment',
      'administrative',
    ].freeze

    has_many :contact_alert_subscriptions, dependent: :destroy
    has_many :contacts, through: :contact_alert_subscriptions, source: :contact

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
    validates :category, presence: true, inclusion: { in: VALID_CATEGORIES }

    scope :active, -> { where(active: true) }
    scope :by_category, ->(category) { where(category: category) }
    scope :system_alerts, -> { by_category('system') }

    # Attributes in initial_definitions that are not database columns
    def self.non_database_attributes
      [:visibility_check, :email_subject]
    end

    def self.maintain
      initial_definitions.each do |attrs|
        find_or_create_by!(code: attrs[:code]) do |definition|
          definition.assign_attributes(attrs.except(*non_database_attributes))
        end
      end
    end

    def self.initial_definitions
      [
        # System Category (User-level)
        {
          code: 'new_account',
          name: 'New Account Creation',
          category: 'system',
          description: 'Notification when a new user account is created by an external system',
          visibility_check: ->(_user) { ENV['OKTA_DOMAIN'].present? },
        },
        {
          code: 'account_request',
          name: 'Account Request',
          category: 'system',
          description: 'Notification when a user requests a new account',
          visibility_check: ->(_user) { GrdaWarehouse::Config.get(:request_account_available) },
        },
        {
          code: 'file_upload',
          name: 'File Upload',
          category: 'system',
          description: 'Notification when files are uploaded to the system',
        },
        {
          code: 'vispdat_completed',
          name: 'VI-SPDAT Completed',
          category: 'system',
          description: 'Notification when a VI-SPDAT assessment is submitted',
          visibility_check: lambda(&:can_edit_vspdat?),
        },
        {
          code: 'client_added',
          name: 'Client Added',
          category: 'system',
          description: 'Notification when a new client is added to authoritative data source',
          visibility_check: ->(_user) { GrdaWarehouse::DataSource.authoritative.exists? },
        },
        {
          code: 'anomaly_identified',
          name: 'Anomaly Identified',
          category: 'system',
          description: 'Notification when data anomalies are detected',
        },
        # Client Metric Alerts
        {
          code: 'metric_days_homeless_threshold',
          name: 'Days Homeless Threshold Crossed',
          email_subject: 'Client Metric Alert: Days Homeless Threshold Crossed',
          category: 'system',
          description: 'Notification when clients cross the threshold for days homeless in the last 3 years',
          visibility_check: ->(_user) { GrdaWarehouse::Monitoring::MetricDefinition.active.exists?(name: 'days_homeless_last_three_years') },
        },
        {
          code: 'metric_household_size_threshold',
          name: 'Household Size Threshold Crossed',
          email_subject: 'Client Metric Alert: Household Size Threshold Crossed',
          category: 'system',
          description: 'Notification when clients cross the threshold for household size changes',
          visibility_check: lambda do |_user|
            GrdaWarehouse::Monitoring::MetricDefinition.active.where(
              name: ['min_household_size', 'max_household_size'],
            ).exists?
          end,
        },
        # Data Quality Category (Project/Org-level)
        {
          code: 'data_quality_report',
          name: 'Data Quality Report Available',
          category: 'data_quality',
          description: 'Notification when a data quality report is ready',
        },
      ]
    end

    # Check if this alert should be shown to a specific user
    def show_to?(user)
      definition = self.class.initial_definitions.find { |d| d[:code] == code }
      # Note, we default to true if no visibility check is defined
      return true unless definition&.key?(:visibility_check)

      definition[:visibility_check].call(user)
    end

    # Get email subject for this alert type
    def email_subject
      definition = self.class.initial_definitions.find { |d| d[:code] == code }
      definition&.dig(:email_subject) || "Alert: #{name}"
    end

    def subscribed_users
      GrdaWarehouse::Contact::User.
        joins(:contact_alert_subscriptions).
        where(
          contact_alert_subscriptions: {
            alert_definition_id: id,
            active: true,
          },
        ).
        includes(:user).
        map(&:user)
    end
  end
end
