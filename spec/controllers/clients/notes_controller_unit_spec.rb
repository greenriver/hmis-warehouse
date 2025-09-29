# frozen_string_literal: false

require 'rails_helper'

RSpec.describe Clients::NotesController, type: :controller do
  let!(:user) { create :user }
  let!(:admin) { create :acl_user }
  let!(:admin_role) { create :admin_role }
  let!(:source_client) { create :authoritative_hud_client }
  let!(:client) { create :fixed_destination_client }
  let!(:warehouse_client) { create :warehouse_client, source: source_client, destination: client }

  before do
    Collection.maintain_system_groups
    setup_access_control(admin, admin_role, Collection.system_collection(:data_sources))
    sign_in admin
    allow(controller).to receive(:current_user).and_return(admin)
  end

  describe '#create string mutation operations' do
    let(:controller_instance) { described_class.new }
    let(:flash_hash) { {} }

    before do
      allow(controller_instance).to receive(:current_user).and_return(admin)
      allow(controller_instance).to receive(:flash).and_return(flash_hash)
      allow(controller_instance).to receive(:redirect_to)
      allow(controller_instance).to receive(:polymorphic_path).and_return('/client/1/notes')
      allow(controller_instance).to receive(:client_notes_path_generator).and_return('client_notes')
      allow(controller_instance).to receive(:client_notes_path).and_return('/client/1/notes')
      allow(GrdaWarehouse::ClientNotes::Base).to receive(:available_types).and_return([double(to_s: 'GrdaWarehouse::ClientNotes::WindowNote')])
      allow(client.notes).to receive(:create!).and_return(true)
      allow(TokenMailer).to receive(:note_added).and_return(double(deliver_later: true))
      allow(Token).to receive(:tokenize).and_return('test_token')

      controller_instance.instance_variable_set(:@client, client)
    end

    context 'when testing create method with multiple notification recipients' do
      it 'builds notification message with string concatenation (sent << and notice +=)' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              client_id: client.id,
              note: {
                note: 'Test note',
                type: 'GrdaWarehouse::ClientNotes::WindowNote',
                send_notification: '1',
                recipients: [admin.id, user.id],
              },
            },
          ),
        )
        allow(User).to receive(:find).with(admin.id).and_return(admin)
        allow(User).to receive(:find).with(user.id).and_return(user)

        controller_instance.send(:create)

        # Verify string mutations: sent << user.name (line 56) and notice += '; sent to: ' + sent.join(', ') + '.' (line 59)
        expect(flash_hash[:notice]).to include('Added new note; sent to:')
        expect(flash_hash[:notice]).to include(admin.name)
        expect(flash_hash[:notice]).to include(user.name)
        expect(flash_hash[:notice]).to end_with('.')
      end
    end

    context 'when testing create method with single notification recipient' do
      it 'builds notification message with single recipient' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              client_id: client.id,
              note: {
                note: 'Test note',
                type: 'GrdaWarehouse::ClientNotes::WindowNote',
                send_notification: '1',
                recipients: [admin.id],
              },
            },
          ),
        )
        allow(User).to receive(:find).with(admin.id).and_return(admin)

        controller_instance.send(:create)

        expected_notice = "Added new note; sent to: #{admin.name}."
        expect(flash_hash[:notice]).to eq(expected_notice)
      end
    end

    context 'when testing create method with no notification recipients' do
      it 'does not modify notice message when no recipients' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              client_id: client.id,
              note: {
                note: 'Test note',
                type: 'GrdaWarehouse::ClientNotes::WindowNote',
                send_notification: '',
                recipients: [],
              },
            },
          ),
        )

        controller_instance.send(:create)

        expect(flash_hash[:notice]).to eq('Added new note')
      end
    end

    context 'when testing create method with blank recipients' do
      it 'filters out blank recipient IDs and builds proper notice' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              client_id: client.id,
              note: {
                note: 'Test note',
                type: 'GrdaWarehouse::ClientNotes::WindowNote',
                send_notification: '1',
                recipients: [admin.id, '', nil, user.id],
              },
            },
          ),
        )
        allow(User).to receive(:find).with(admin.id).and_return(admin)
        allow(User).to receive(:find).with(user.id).and_return(user)

        controller_instance.send(:create)

        # Should filter out blanks and process only valid user IDs
        expect(flash_hash[:notice]).to include('Added new note; sent to:')
        expect(flash_hash[:notice]).to include(admin.name)
        expect(flash_hash[:notice]).to include(user.name)
        expect(flash_hash[:notice]).to end_with('.')
      end
    end

    context 'when testing create method with invalid user ID' do
      it 'skips invalid users and continues building sent array' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(
            {
              client_id: client.id,
              note: {
                note: 'Test note',
                type: 'GrdaWarehouse::ClientNotes::WindowNote',
                send_notification: '1',
                recipients: [admin.id, 99999], # 99999 is invalid
              },
            },
          ),
        )
        allow(User).to receive(:find).with(admin.id).and_return(admin)
        allow(User).to receive(:find).with(99999).and_return(nil)

        controller_instance.send(:create)

        # Should only include the valid user in the notification
        expected_notice = "Added new note; sent to: #{admin.name}."
        expect(flash_hash[:notice]).to eq(expected_notice)
      end
    end
  end
end
