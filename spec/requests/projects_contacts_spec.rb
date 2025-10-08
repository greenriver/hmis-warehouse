# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Projects contacts', type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_imports: true) }
  let(:collection) { create(:collection, collection_type: 'Projects') }
  let(:project) { create(:hud_project) }

  before do
    collection.set_viewables(projects: [project.id])
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'POST /projects/:project_id/contacts' do
    it 'creates a project contact and redirects to the contacts index' do
      contact_user = create(:user)

      expect do
        post(
          project_contacts_path(project),
          params: {
            contact: {
              user_id: contact_user.id,
            },
          },
        )
      end.to change(GrdaWarehouse::Contact::Project, :count).by(1)

      aggregate_failures do
        contact = project.contacts.last
        expect(contact.user).to eq(contact_user)
        expect(response).to redirect_to(project_contacts_path(project))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'PATCH /projects/:project_id/contacts/:id' do
    it 'updates the project contact and redirects to the contacts index' do
      contact = create(:grda_warehouse_contact_project, entity_id: project.id)
      new_user = create(:user)

      patch(
        project_contact_path(project, contact),
        params: {
          contact: {
            user_id: new_user.id,
          },
        },
      )

      aggregate_failures do
        expect(contact.reload.user).to eq(new_user)
        expect(response).to redirect_to(project_contacts_path(project))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'DELETE /projects/:project_id/contacts/:id' do
    it 'soft deletes the project contact and redirects to the contacts index' do
      contact = create(:grda_warehouse_contact_project, entity_id: project.id)

      expect do
        delete project_contact_path(project, contact)
      end.to change { contact.reload.deleted_at.present? }.from(false).to(true)

      aggregate_failures do
        expect(response).to redirect_to(project_contacts_path(project))
        expect(flash[:notice]).to be_present
      end
    end
  end
end
