###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Contact
  class Base < GrdaWarehouseBase
    self.table_name = :contacts
    acts_as_paranoid

    # TODO: enable this after 20251007133153_fixup_contacts.rb is run (release-186 or later)
    # self.ignored_columns = ['first_name', 'last_name', 'email']

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :email

    belongs_to :user, optional: true, class_name: '::User'
    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :report_tokens, foreign_key: :contact_id, class_name: 'GrdaWarehouse::ReportToken'
    has_many :contact_alert_subscriptions, dependent: :destroy, foreign_key: :contact_id, inverse_of: :contact
    has_many :alert_definitions, through: :contact_alert_subscriptions

    scope :system_contacts, -> { where(type: 'GrdaWarehouse::Contact::User') }
    scope :not_system_contacts, -> { where.not(type: 'GrdaWarehouse::Contact::User') }
    scope :active_subscriptions, -> do
      joins(:contact_alert_subscriptions).merge(GrdaWarehouse::ContactAlertSubscription.active)
    end

    # Excludes contacts whose entities (projects or organizations) have been soft-deleted
    # System contacts (User type) are always included as they don't have entities
    # Note: Projects and Organizations use acts_as_paranoid, so .select(:id) automatically excludes deleted records
    scope :with_active_entities, -> do
      where(type: 'GrdaWarehouse::Contact::User').
        or(where(type: 'GrdaWarehouse::Contact::Project', entity_id: GrdaWarehouse::Hud::Project.select(:id))).
        or(where(type: 'GrdaWarehouse::Contact::Organization', entity_id: GrdaWarehouse::Hud::Organization.select(:id)))
    end

    def self.available_users(entity, include_current: false)
      scope = ::User.active.not_system.order(last_name: :asc, first_name: :asc)
      scope = scope.where.not(id: entity.contacts.pluck(:user_id)) unless include_current
      scope
    end

    def email
      user&.email || self[:email]
    end

    def full_name
      user&.name || 'Unknown'
    end

    def full_name_with_email
      user&.name_with_email || 'Unknown'
    end

    # Check if contact is subscribed to a specific alert
    def subscribed_to?(alert_definition_code)
      alert_definitions.active.exists?(code: alert_definition_code)
    end

    # Get only active subscriptions
    def active_alert_subscriptions
      contact_alert_subscriptions.
        joins(:alert_definition).
        where(active: true).
        merge(GrdaWarehouse::AlertDefinition.active)
    end

    # Subscribe to an alert by code
    def subscribe_to!(alert_definition_code)
      definition = GrdaWarehouse::AlertDefinition.active.find_by!(code: alert_definition_code)
      contact_alert_subscriptions.find_or_create_by!(alert_definition: definition)
    end

    # Unsubscribe from an alert by code
    def unsubscribe_from!(alert_definition_code)
      definition = GrdaWarehouse::AlertDefinition.find_by!(code: alert_definition_code)
      contact_alert_subscriptions.where(alert_definition: definition).destroy_all
    end
  end
end
