###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ContactAlertSubscription < GrdaWarehouseBase
    has_paper_trail(
      meta: {
        referenced_user_id: :user_id_for_audit,
      },
    )

    belongs_to :contact, class_name: 'GrdaWarehouse::Contact::Base', foreign_key: :contact_id, inverse_of: :contact_alert_subscriptions
    belongs_to :alert_definition

    validates :contact_id, uniqueness: { scope: :alert_definition_id }

    scope :active, -> do
      where(active: true).
        joins(:alert_definition).
        merge(AlertDefinition.active)
    end

    delegate :code, :name, :category, to: :alert_definition, prefix: :alert

    # For PaperTrail: link this subscription change to the user being edited
    def user_id_for_audit
      return unless contact.is_a?(GrdaWarehouse::Contact::User)

      contact.entity_id
    end

    # Describe changes for audit history display
    def self.describe_changes(version, changeset)
      return [] unless changeset

      case version.event
      when 'create'
        alert_name = alert_name_from_version(version, changeset)
        ["Subscribed to alert: #{alert_name}"]
      when 'destroy'
        alert_name = alert_name_from_version(version, changeset)
        ["Unsubscribed from alert: #{alert_name}"]
      when 'update'
        changes = []
        if changeset.key?('active')
          alert_name = alert_name_from_version(version, changeset)
          _from, to = changeset['active']
          if to
            changes << "Re-activated subscription to alert: #{alert_name}"
          else
            changes << "Deactivated subscription to alert: #{alert_name}"
          end
        end
        changes
      else
        []
      end
    end

    # Extract alert name from version, trying multiple approaches
    def self.alert_name_from_version(version, changeset)
      # Try to get alert_definition_id from changeset first
      if changeset.key?('alert_definition_id')
        alert_definition_id = changeset['alert_definition_id'].last
        definition = GrdaWarehouse::AlertDefinition.find_by(id: alert_definition_id) if alert_definition_id
        return definition.name if definition
      end

      # Try to load from the reified object or current record
      begin
        subscription = version.reify || find_by(id: version.item_id)
        return subscription.alert_definition.name if subscription&.alert_definition
      rescue StandardError
        # Fall through to Unknown Alert
      end

      'Unknown Alert'
    end

    # Migrate existing user notification preferences to alert subscriptions
    def self.migrate_user_notification_preferences!
      migrate_user_system_alerts!
      migrate_project_and_organization_contacts!
    end

    # Migrate user-level system alert preferences from old boolean columns
    def self.migrate_user_system_alerts!
      mappings = {
        'notify_on_new_account' => 'new_account',
        'notify_on_vispdat_completed' => 'vispdat_completed',
        'notify_on_client_added' => 'client_added',
        'notify_on_anomaly_identified' => 'anomaly_identified',
        'receive_account_request_notifications' => 'account_request',
        'receive_file_upload_notifications' => 'file_upload',
      }

      User.find_each do |user|
        needs_system_contact = false
        subscriptions_to_create = []

        mappings.each do |old_column, alert_code|
          next unless user.respond_to?(old_column)
          next unless user.send(old_column)

          definition = AlertDefinition.find_by(code: alert_code)
          next unless definition

          needs_system_contact = true
          subscriptions_to_create << {
            alert_definition_id: definition.id,
            active: true,
          }
        end

        if needs_system_contact && subscriptions_to_create.any?
          contact = user.system_contact!
          subscriptions_to_create.each do |attrs|
            contact.contact_alert_subscriptions.find_or_create_by!(attrs)
          end
        end
      end
    end

    # Subscribe all existing project and organization contacts to data quality reports
    # This ensures existing contacts continue to receive reports they were getting before
    def self.migrate_project_and_organization_contacts!
      data_quality_definition = AlertDefinition.find_by(code: 'data_quality_report')
      return unless data_quality_definition

      # Subscribe all project contacts
      GrdaWarehouse::Contact::Project.find_each do |contact|
        contact.contact_alert_subscriptions.find_or_create_by!(
          alert_definition_id: data_quality_definition.id,
          active: true,
        )
      end

      # Subscribe all organization contacts
      GrdaWarehouse::Contact::Organization.find_each do |contact|
        contact.contact_alert_subscriptions.find_or_create_by!(
          alert_definition_id: data_quality_definition.id,
          active: true,
        )
      end
    end
  end
end
