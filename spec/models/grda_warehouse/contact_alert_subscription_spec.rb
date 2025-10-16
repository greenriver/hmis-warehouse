###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ContactAlertSubscription, type: :model do
  let(:user) { create(:user) }
  let(:alert_definition) { create(:alert_definition, code: 'new_account', name: 'New Account Creation') }
  let(:contact) { create(:grda_warehouse_contact_user, entity: user, user: user) }

  describe 'PaperTrail tracking' do
    # Enable PaperTrail for these tests
    before { PaperTrail.enabled = true }
    after { PaperTrail.enabled = false }

    it 'tracks creation with referenced_user_id' do
      subscription = nil
      expect do
        subscription = described_class.create!(
          contact: contact,
          alert_definition: alert_definition,
          active: true,
        )
      end.to change(GrdaWarehouse::Version, :count).by(1)

      version = GrdaWarehouse::Version.last
      expect(version.item_type).to eq('GrdaWarehouse::ContactAlertSubscription')
      expect(version.item_id).to eq(subscription.id)
      expect(version.event).to eq('create')
      expect(version.referenced_user_id).to eq(user.id)
    end

    it 'tracks destruction with referenced_user_id' do
      subscription = create(
        :contact_alert_subscription,
        contact: contact,
        alert_definition: alert_definition,
      )

      expect do
        subscription.destroy
      end.to change(GrdaWarehouse::Version, :count).by(1)

      version = GrdaWarehouse::Version.last
      expect(version.event).to eq('destroy')
      expect(version.referenced_user_id).to eq(user.id)
    end

    it 'tracks updates with referenced_user_id' do
      subscription = create(
        :contact_alert_subscription,
        contact: contact,
        alert_definition: alert_definition,
        active: true,
      )

      expect do
        subscription.update!(active: false)
      end.to change(GrdaWarehouse::Version, :count).by(1)

      version = GrdaWarehouse::Version.last
      expect(version.event).to eq('update')
      expect(version.referenced_user_id).to eq(user.id)
    end
  end

  describe '.describe_changes' do
    # Enable PaperTrail for these tests
    before { PaperTrail.enabled = true }
    after { PaperTrail.enabled = false }

    let(:subscription) do
      create(
        :contact_alert_subscription,
        contact: contact,
        alert_definition: alert_definition,
      )
    end

    context 'when subscription is created' do
      it 'returns subscription message' do
        version = subscription.versions.last
        changeset = version.changeset

        result = described_class.describe_changes(version, changeset)

        expect(result).to eq(['Subscribed to alert: New Account Creation'])
      end
    end

    context 'when subscription is destroyed' do
      it 'returns unsubscription message' do
        subscription.destroy
        version = subscription.versions.last
        changeset = version.changeset

        result = described_class.describe_changes(version, changeset)

        expect(result).to eq(['Unsubscribed from alert: New Account Creation'])
      end
    end

    context 'when subscription is deactivated' do
      it 'returns deactivation message' do
        subscription.update!(active: false)
        version = subscription.versions.last
        changeset = version.changeset

        result = described_class.describe_changes(version, changeset)

        expect(result).to eq(['Deactivated subscription to alert: New Account Creation'])
      end
    end

    context 'when subscription is reactivated' do
      before { subscription.update!(active: false) }

      it 'returns reactivation message' do
        subscription.update!(active: true)
        version = subscription.versions.last
        changeset = version.changeset

        result = described_class.describe_changes(version, changeset)

        expect(result).to eq(['Re-activated subscription to alert: New Account Creation'])
      end
    end
  end

  describe '#user_id_for_audit' do
    context 'when contact is a User contact' do
      it 'returns the entity_id' do
        subscription = build(
          :contact_alert_subscription,
          contact: contact,
        )

        expect(subscription.user_id_for_audit).to eq(user.id)
      end
    end

    context 'when contact is not a User contact' do
      let(:org_contact) { create(:grda_warehouse_contact_organization) }

      it 'returns nil' do
        subscription = build(
          :contact_alert_subscription,
          contact: org_contact,
        )

        expect(subscription.user_id_for_audit).to be_nil
      end
    end
  end

  describe '.migrate_project_and_organization_contacts!' do
    let(:data_source) { create(:grda_warehouse_data_source) }
    let(:organization) { create(:grda_warehouse_hud_organization, data_source: data_source) }
    let(:project) { create(:grda_warehouse_hud_project, data_source: data_source, organization: organization) }
    let(:data_quality_alert) do
      GrdaWarehouse::AlertDefinition.find_or_create_by!(code: 'data_quality_report') do |ad|
        ad.name = 'Data Quality Report Available'
        ad.category = 'data_quality'
        ad.active = true
      end
    end

    before do
      data_quality_alert # ensure alert exists
    end

    context 'with existing project contacts' do
      let!(:project_contact1) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: create(:user),
        )
      end
      let!(:project_contact2) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: create(:user),
        )
      end

      it 'subscribes all project contacts to data quality reports' do
        expect do
          described_class.migrate_project_and_organization_contacts!
        end.to change(described_class, :count).by(2)

        expect(project_contact1.reload.subscribed_to?('data_quality_report')).to be true
        expect(project_contact2.reload.subscribed_to?('data_quality_report')).to be true
      end

      it 'is idempotent - does not create duplicates' do
        described_class.migrate_project_and_organization_contacts!

        expect do
          described_class.migrate_project_and_organization_contacts!
        end.not_to(change(described_class, :count))
      end
    end

    context 'with existing organization contacts' do
      let!(:org_contact1) do
        create(
          :grda_warehouse_contact_organization,
          entity: organization,
          user: create(:user),
        )
      end
      let!(:org_contact2) do
        create(
          :grda_warehouse_contact_organization,
          entity: organization,
          user: create(:user),
        )
      end

      it 'subscribes all organization contacts to data quality reports' do
        expect do
          described_class.migrate_project_and_organization_contacts!
        end.to change(described_class, :count).by(2)

        expect(org_contact1.reload.subscribed_to?('data_quality_report')).to be true
        expect(org_contact2.reload.subscribed_to?('data_quality_report')).to be true
      end
    end

    context 'with mixed project and organization contacts' do
      let!(:project_contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: create(:user),
        )
      end
      let!(:org_contact) do
        create(
          :grda_warehouse_contact_organization,
          entity: organization,
          user: create(:user),
        )
      end

      it 'subscribes both types of contacts' do
        expect do
          described_class.migrate_project_and_organization_contacts!
        end.to change(described_class, :count).by(2)

        expect(project_contact.reload.subscribed_to?('data_quality_report')).to be true
        expect(org_contact.reload.subscribed_to?('data_quality_report')).to be true
      end
    end

    context 'when data quality alert definition does not exist' do
      before do
        GrdaWarehouse::AlertDefinition.where(code: 'data_quality_report').delete_all
      end

      let!(:project_contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: create(:user),
        )
      end

      it 'does not create any subscriptions' do
        expect do
          described_class.migrate_project_and_organization_contacts!
        end.not_to(change(described_class, :count))
      end
    end
  end

  describe '.migrate_user_notification_preferences!' do
    it 'calls both migration methods' do
      expect(described_class).to receive(:migrate_user_system_alerts!)
      expect(described_class).to receive(:migrate_project_and_organization_contacts!)

      described_class.migrate_user_notification_preferences!
    end
  end
end
