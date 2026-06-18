# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe SecureFilesController, type: :request do
  include ActiveJob::TestHelper

  let(:recipient_role) { create :secure_file_recipient }
  let(:admin_role) { create :secure_file_admin }
  let(:collection) { create :collection }

  # Bob, in the bug report: can use the feature and uploads a file for Alice,
  # but only has assigned (non-admin) access.
  let(:sender) { create :acl_user }
  # Alice: the recipient of the file.
  let(:recipient) { create :acl_user }
  # An unrelated user with the feature but no relationship to the file.
  let(:bystander) { create :acl_user }
  let(:admin) { create :acl_user }
  # Bob after his secure-file access was revoked: still the sender of a file, but
  # no longer permitted to use the feature at all (an empty role).
  let(:former_sender) { create :acl_user }
  let!(:former_file) { create :secure_file, sender_id: former_sender.id, recipient_id: recipient.id }

  let!(:file) { create :secure_file, sender_id: sender.id, recipient_id: recipient.id }

  before do
    setup_access_control(sender, recipient_role, collection)
    setup_access_control(recipient, recipient_role, collection)
    setup_access_control(bystander, recipient_role, collection)
    setup_access_control(admin, admin_role, collection)
    setup_access_control(former_sender, create(:role), collection)
  end

  describe 'GET #show (download)' do
    context 'as a non-admin sender who still holds the role' do
      before { sign_in sender }

      it 'downloads a file it uploaded' do
        # The reported bug: a sender with assigned access hit an error opening
        # their own upload. Retaining the role grants access to files you sent.
        get secure_file_path(file)
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(file.secure_file.download)
      end
    end

    context 'as the recipient' do
      before { sign_in recipient }

      it 'downloads the received file' do
        get secure_file_path(file)
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(file.secure_file.download)
      end
    end

    context 'as an admin' do
      before { sign_in admin }

      it 'downloads any file' do
        get secure_file_path(file)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as an unrelated user' do
      before { sign_in bystander }

      it 'cannot download a file it neither sent nor received' do
        get secure_file_path(file)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'as a sender who has lost the role' do
      before { sign_in former_sender }

      it 'cannot download a file it uploaded once access is revoked' do
        # Access follows the role: with no permission the require_* gate redirects
        # away before set_file ever scopes the lookup.
        get secure_file_path(former_file)
        expect(response).to have_http_status(:redirect)
      end
    end

    # show streams the attachment straight from ActiveStorage; this pins that the
    # stored content type and bytes round-trip for a non-default payload.
    context 'with a non-default content type' do
      let(:attached_content) { 'secure activestorage payload' }

      before do
        file.secure_file.attach(
          io: StringIO.new(attached_content),
          filename: 'report.txt',
          content_type: 'text/plain',
        )
      end

      context 'as the recipient' do
        before { sign_in recipient }

        it 'serves the stored content and content type' do
          get secure_file_path(file)
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(attached_content)
          expect(response.media_type).to eq('text/plain')
        end
      end
    end
  end

  describe 'DELETE #destroy (remove)' do
    context 'as a non-admin sender who still holds the role' do
      before { sign_in sender }

      it 'removes a file it uploaded' do
        delete secure_file_path(file)
        expect(response).to redirect_to(secure_files_path)
        expect(GrdaWarehouse::SecureFile.find_by(id: file.id)).to be_nil
      end
    end

    context 'as the recipient' do
      before { sign_in recipient }

      it 'removes the received file' do
        delete secure_file_path(file)
        expect(response).to redirect_to(secure_files_path)
        expect(GrdaWarehouse::SecureFile.find_by(id: file.id)).to be_nil
      end
    end

    context 'as an unrelated user' do
      before { sign_in bystander }

      it 'cannot remove a file it neither sent nor received' do
        delete secure_file_path(file)
        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::SecureFile.find_by(id: file.id)).to be_present
      end
    end

    context 'as a sender who has lost the role' do
      before { sign_in former_sender }

      it 'cannot remove a file it uploaded once access is revoked' do
        delete secure_file_path(former_file)
        expect(response).to have_http_status(:redirect)
        expect(GrdaWarehouse::SecureFile.find_by(id: former_file.id)).to be_present
      end
    end
  end

  # Every secure file expires 1 month after creation: viewable_by gates both
  # download and removal and is scoped .unexpired, so an expired file must be
  # unreachable for download AND removal regardless of role.
  describe 'expired files (older than 1 month)' do
    let!(:expired_file) do
      create :secure_file, sender_id: sender.id, recipient_id: recipient.id, created_at: 2.months.ago
    end

    context 'as the recipient' do
      before { sign_in recipient }

      it 'cannot download an expired file it received' do
        get secure_file_path(expired_file)
        expect(response).to have_http_status(:not_found)
      end
    end

    # Guards the sender's path specifically: expiry must still bound it, even
    # though holding the role otherwise grants access to files you uploaded.
    context 'as a non-admin sender' do
      before { sign_in sender }

      it 'cannot remove an expired file it uploaded' do
        delete secure_file_path(expired_file)
        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::SecureFile.find_by(id: expired_file.id)).to be_present
      end
    end
  end

  # viewable_by was broadened so senders can reach their own uploads for
  # download/removal, but those uploads must still render only under "Sent",
  # never "Received". Guards against the broadened auth scope leaking into the
  # recipient-facing list.
  describe 'GET #index (Received vs. Sent lists)' do
    context 'as an assigned sender who received nothing' do
      before { sign_in sender }

      it 'lists its upload under Sent and shows an empty Received list' do
        get secure_files_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('test file')
        expect(response.body).to include('You have not received any secure files')
      end
    end

    context 'as the recipient' do
      before { sign_in recipient }

      it 'lists the file under Received and shows an empty Sent list' do
        get secure_files_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('test file')
        expect(response.body).to include('You have not sent any secure files')
      end
    end

    # index is gated by the same permission as show/destroy/create, so a user who
    # lost the role can no longer reach it at all: the authorization gate redirects
    # away before either list is rendered.
    context 'as a sender who has lost the role' do
      before { sign_in former_sender }

      it 'cannot reach the index once access is revoked' do
        get secure_files_path
        expect(response).to have_http_status(:redirect)
      end
    end

    # "Received" means you're the recipient, for everyone. An admin can still
    # download/remove any file by id (viewable_by), but the list is not a
    # system-wide view — it shows only files sent to the admin.
    context 'as an admin who neither sent nor received the file' do
      before { sign_in admin }

      it 'does not list files the admin did not receive' do
        get secure_files_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('You have not received any secure files')
      end
    end
  end

  describe 'POST #create (upload)' do
    let(:upload) do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/images/test_photo.jpg'), 'image/jpeg')
    end

    def upload_params(recipient_ids:, send_notifications: false)
      {
        secure_file: {
          name: 'uploaded report',
          file: upload,
          recipients: Array(recipient_ids).map(&:to_s),
          send_notifications: send_notifications ? '1' : '0',
        },
      }
    end

    # create writes a file into a recipient's inbox, so it must be gated by the
    # same permission as show/destroy: a user who lost the role cannot upload,
    # exactly as they can no longer download or remove.
    context 'as a sender who has lost the role' do
      before { sign_in former_sender }

      it 'cannot upload once access is revoked' do
        expect do
          post secure_files_path, params: upload_params(recipient_ids: recipient.id)
        end.not_to change(GrdaWarehouse::SecureFile, :count)
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'as an assigned sender' do
      before { sign_in sender }

      it 'stores one attached file per recipient and notifies each when asked' do
        first_recipient = create :acl_user
        second_recipient = create :acl_user

        expect do
          post secure_files_path, params: upload_params(
            recipient_ids: [first_recipient.id, second_recipient.id],
            send_notifications: true,
          )
        end.to have_enqueued_mail(NotifyUser, :secure_file_received).twice

        expect(response).to redirect_to(secure_files_path)
        created = GrdaWarehouse::SecureFile.where(sender_id: sender.id, recipient_id: [first_recipient.id, second_recipient.id])
        expect(created.count).to eq(2)
        expect(created.map { |f| f.secure_file.attached? }).to all(be(true))
      end

      # All recipients commit together or none do (controller wraps the loop in a
      # transaction): a failure on a later recipient must leave no file behind for
      # an earlier one. An invalid recipient_id fails the required belongs_to.
      it 'rolls back every file and re-renders the form when any recipient is invalid' do
        valid_recipient = create :acl_user
        missing_recipient_id = User.maximum(:id).to_i + 1

        expect do
          post secure_files_path, params: upload_params(recipient_ids: [valid_recipient.id, missing_recipient_id])
        end.not_to change(GrdaWarehouse::SecureFile, :count)

        expect(GrdaWarehouse::SecureFile.where(sender_id: sender.id, recipient_id: valid_recipient.id)).to be_empty
        expect(response).to have_http_status(:ok)
      end

      # Notifications fire only after the transaction commits, so a rolled-back
      # upload must never email a recipient about a file that no longer exists.
      it 'notifies no recipient when the upload fails partway' do
        valid_recipient = create :acl_user
        missing_recipient_id = User.maximum(:id).to_i + 1

        expect do
          post secure_files_path, params: upload_params(
            recipient_ids: [valid_recipient.id, missing_recipient_id],
            send_notifications: true,
          )
        end.not_to have_enqueued_mail(NotifyUser, :secure_file_received)
      end
    end
  end
end
