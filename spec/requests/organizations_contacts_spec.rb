###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organizations contacts', type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_imports: true) }
  let(:collection) { create(:collection) }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:organization) { create(:grda_warehouse_hud_organization, data_source: data_source) }

  before do
    collection.set_viewables(data_sources: [data_source.id])
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'POST /organizations/:organization_id/contacts' do
    it 'creates a contact and redirects to the contacts index' do
      contact_user = create(:user)

      expect do
        post(
          organization_contacts_path(organization),
          params: {
            contact: {
              user_id: contact_user.id,
            },
          },
        )
      end.to change(GrdaWarehouse::Contact::Organization, :count).by(1)

      aggregate_failures do
        contact = organization.contacts.last
        expect(contact.user).to eq(contact_user)
        expect(response).to redirect_to(organization_contacts_path(organization))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'PATCH /organizations/:organization_id/contacts/:id' do
    it 'updates the contact and redirects to the contacts index' do
      contact = create(:grda_warehouse_contact_organization, entity_id: organization.id)
      new_user = create(:user)

      patch(
        organization_contact_path(organization, contact),
        params: {
          contact: {
            user_id: new_user.id,
          },
        },
      )

      aggregate_failures do
        expect(contact.reload.user).to eq(new_user)
        expect(response).to redirect_to(organization_contacts_path(organization))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'DELETE /organizations/:organization_id/contacts/:id' do
    it 'soft deletes the contact and redirects to the contacts index' do
      contact = create(:grda_warehouse_contact_organization, entity_id: organization.id)

      expect do
        delete organization_contact_path(organization, contact)
      end.to change { contact.reload.deleted_at.present? }.from(false).to(true)

      aggregate_failures do
        expect(response).to redirect_to(organization_contacts_path(organization))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'Alert Subscriptions' do
    let(:alert_definition_1) do
      create(
        :alert_definition,
        code: 'test_alert_1',
        name: 'Test Alert 1',
        category: 'client_activity',
      )
    end
    let(:alert_definition_2) do
      create(
        :alert_definition,
        code: 'test_alert_2',
        name: 'Test Alert 2',
        category: 'data_quality',
      )
    end

    describe 'POST /organizations/:organization_id/contacts with alert_definition_ids' do
      it 'creates contact with alert subscriptions' do
        contact_user = create(:user)

        expect do
          post(
            organization_contacts_path(organization),
            params: {
              contact: {
                user_id: contact_user.id,
                alert_definition_ids: [alert_definition_1.id, alert_definition_2.id],
              },
            },
          )
        end.to change(GrdaWarehouse::Contact::Organization, :count).by(1).
          and change(GrdaWarehouse::ContactAlertSubscription, :count).by(2)

        aggregate_failures do
          contact = organization.contacts.last
          expect(contact.user).to eq(contact_user)
          expect(contact.alert_definitions).to contain_exactly(
            alert_definition_1,
            alert_definition_2,
          )
          expect(response).to redirect_to(organization_contacts_path(organization))
        end
      end
    end

    describe 'PATCH /organizations/:organization_id/contacts/:id with alert_definition_ids' do
      it 'updates contact alert subscriptions' do
        contact = create(
          :grda_warehouse_contact_organization,
          entity_id: organization.id,
        )
        contact.alert_definitions << alert_definition_1

        patch(
          organization_contact_path(organization, contact),
          params: {
            contact: {
              user_id: contact.user_id,
              alert_definition_ids: [alert_definition_2.id],
            },
          },
        )

        aggregate_failures do
          expect(contact.reload.alert_definitions).to contain_exactly(alert_definition_2)
          expect(response).to redirect_to(organization_contacts_path(organization))
        end
      end

      it 'removes all alert subscriptions when alert_definition_ids is empty' do
        contact = create(
          :grda_warehouse_contact_organization,
          entity_id: organization.id,
        )
        contact.alert_definitions << [alert_definition_1, alert_definition_2]

        patch(
          organization_contact_path(organization, contact),
          params: {
            contact: {
              user_id: contact.user_id,
              alert_definition_ids: [],
            },
          },
        )

        aggregate_failures do
          expect(contact.reload.alert_definitions).to be_empty
          expect(response).to redirect_to(organization_contacts_path(organization))
        end
      end
    end
  end
end
