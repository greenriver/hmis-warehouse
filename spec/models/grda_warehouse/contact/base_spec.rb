###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Contact::Base, type: :model do
  let!(:data_source) { create :source_data_source }
  let!(:organization) { create :hud_organization, data_source: data_source }
  let!(:project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let!(:user) { create :user }
  let!(:alert_definition) { create :alert_definition, code: 'test_alert', name: 'Test Alert', category: 'data_quality' }

  describe 'dependent destroy' do
    context 'when a project is deleted' do
      let!(:project_contact) do
        GrdaWarehouse::Contact::Project.create!(
          user: user,
          entity: project,
        )
      end

      let!(:alert_subscription) do
        GrdaWarehouse::ContactAlertSubscription.create!(
          contact: project_contact,
          alert_definition: alert_definition,
        )
      end

      it 'destroys associated contacts' do
        expect do
          project.destroy
        end.to change(GrdaWarehouse::Contact::Project, :count).by(-1)
      end

      it 'destroys associated alert subscriptions through contacts' do
        expect do
          project.destroy
        end.to change(GrdaWarehouse::ContactAlertSubscription, :count).by(-1)
      end

      it 'soft-deletes the contact (sets deleted_at)' do
        project.destroy
        expect(project_contact.reload.deleted_at).not_to be_nil
      end

      it 'soft-deletes the project (sets DateDeleted)' do
        project.destroy
        expect(project.reload.DateDeleted).not_to be_nil
      end
    end

    context 'when an organization is deleted' do
      let!(:organization_contact) do
        GrdaWarehouse::Contact::Organization.create!(
          user: user,
          entity: organization,
        )
      end

      let!(:alert_subscription) do
        GrdaWarehouse::ContactAlertSubscription.create!(
          contact: organization_contact,
          alert_definition: alert_definition,
        )
      end

      it 'destroys associated contacts' do
        expect do
          organization.destroy
        end.to change(GrdaWarehouse::Contact::Organization, :count).by(-1)
      end

      it 'destroys associated alert subscriptions through contacts' do
        expect do
          organization.destroy
        end.to change(GrdaWarehouse::ContactAlertSubscription, :count).by(-1)
      end

      it 'soft-deletes the contact (sets deleted_at)' do
        organization.destroy
        expect(organization_contact.reload.deleted_at).not_to be_nil
      end

      it 'soft-deletes the organization (sets DateDeleted)' do
        organization.destroy
        expect(organization.reload.DateDeleted).not_to be_nil
      end
    end
  end

  describe '.with_active_entities scope' do
    let!(:active_project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
    let!(:deleted_project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, DateDeleted: Time.current }

    let!(:active_organization) { create :hud_organization, data_source: data_source }
    let!(:deleted_organization) { create :hud_organization, data_source: data_source, DateDeleted: Time.current }

    let!(:active_project_contact) do
      GrdaWarehouse::Contact::Project.create!(
        user: user,
        entity: active_project,
      )
    end

    let!(:deleted_project_contact) do
      # Create contact for active project first, then delete the project
      contact = GrdaWarehouse::Contact::Project.create!(
        user: user,
        entity: active_project,
      )
      # Manually set it to point to deleted project (bypassing validation)
      contact.update_columns(entity_id: deleted_project.id)
      contact
    end

    let!(:active_org_contact) do
      GrdaWarehouse::Contact::Organization.create!(
        user: user,
        entity: active_organization,
      )
    end

    let!(:deleted_org_contact) do
      # Create contact for active organization first, then change entity_id
      contact = GrdaWarehouse::Contact::Organization.create!(
        user: user,
        entity: active_organization,
      )
      # Manually set it to point to deleted organization (bypassing validation)
      contact.update_columns(entity_id: deleted_organization.id)
      contact
    end

    let!(:system_contact) do
      GrdaWarehouse::Contact::User.create!(
        user: user,
        entity_id: user.id,
        entity_type: 'User',
      )
    end

    it 'includes contacts with active projects' do
      expect(GrdaWarehouse::Contact::Base.with_active_entities).to include(active_project_contact)
    end

    it 'excludes contacts with deleted projects' do
      expect(GrdaWarehouse::Contact::Base.with_active_entities).not_to include(deleted_project_contact)
    end

    it 'includes contacts with active organizations' do
      expect(GrdaWarehouse::Contact::Base.with_active_entities).to include(active_org_contact)
    end

    it 'excludes contacts with deleted organizations' do
      expect(GrdaWarehouse::Contact::Base.with_active_entities).not_to include(deleted_org_contact)
    end

    it 'includes system contacts' do
      expect(GrdaWarehouse::Contact::Base.with_active_entities).to include(system_contact)
    end

    it 'returns correct count' do
      # Should include: active_project_contact, active_org_contact, system_contact
      expect(GrdaWarehouse::Contact::Base.with_active_entities.count).to eq(3)
    end
  end
end
