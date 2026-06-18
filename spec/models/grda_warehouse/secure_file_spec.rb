###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::SecureFile, type: :model do
  let(:empty_role) { create :role }
  let(:secure_file_recipient) { create :secure_file_recipient }
  let(:secure_file_admin) { create :secure_file_admin }
  let(:sender) { create :acl_user }
  let(:sender2) { create :acl_user }
  # A sender who, unlike `sender`, still holds the assigned-uploads role.
  let(:sender_with_role) { create :acl_user }
  let(:recipient) { create :acl_user }
  let(:recipient2) { create :acl_user }
  let(:admin) { create :acl_user }
  let!(:file) { create :secure_file, recipient_id: recipient.id, sender_id: sender.id }
  let!(:file2) { create :secure_file, recipient_id: recipient2.id, sender_id: sender2.id }
  let!(:empty_collection) { create :collection }

  before do
    setup_access_control(sender, empty_role, empty_collection)
    setup_access_control(sender2, empty_role, empty_collection)
    setup_access_control(sender_with_role, secure_file_recipient, empty_collection)
    setup_access_control(recipient, secure_file_recipient, empty_collection)
    setup_access_control(recipient2, secure_file_recipient, empty_collection)
    setup_access_control(admin, secure_file_admin, empty_collection)
  end

  describe 'secure files have appropriate permissions' do
    it 'senders with no roles can\'t see the file after upload' do
      expect(GrdaWarehouse::SecureFile.viewable_by(sender).count).to eq 0
    end
    it 'recipient sees exactly the file sent to them, and no others' do
      # contain_exactly subsumes the prior count==1 and first.id==file.id checks:
      # it pins both that recipient sees their file and that file2 (recipient2's)
      # does not leak in.
      expect(GrdaWarehouse::SecureFile.viewable_by(recipient)).to contain_exactly(file)
    end
    it 'admin can see both files' do
      expect(GrdaWarehouse::SecureFile.viewable_by(admin)).to contain_exactly(file, file2)
    end
    it 'a sender who still holds the role can see files they uploaded' do
      uploaded = create :secure_file, sender_id: sender_with_role.id, recipient_id: recipient.id
      # contain_exactly, not include: the assigned branch must surface this user's
      # own upload AND nothing they're unrelated to (e.g. file2). `include` would
      # pass even if the scope leaked other senders'/recipients' files.
      expect(GrdaWarehouse::SecureFile.viewable_by(sender_with_role)).to contain_exactly(uploaded)
    end

    # viewable_by is scoped .unexpired; files older than 1 month must drop out for
    # everyone, including the view-all admin. Mutation guard: deleting .unexpired
    # leaves this red.
    it 'hides expired files even from a view-all admin' do
      expired = create :secure_file, recipient_id: recipient.id, sender_id: sender.id, created_at: 2.months.ago
      expect(GrdaWarehouse::SecureFile.viewable_by(admin)).not_to include(expired)
    end
  end

  # User.can_receive_secure_files backs the recipients dropdown in the upload
  # form. It must union *both* secure-upload permissions; a prior `||` between
  # the two scopes silently dropped the view-all permission, hiding admins.
  describe 'User.can_receive_secure_files' do
    it 'includes a user with only assigned-uploads access' do
      expect(User.can_receive_secure_files).to include(recipient)
    end
    it 'includes a user with only view-all access' do
      # Regression: `||` returned just the assigned-uploads scope, so this
      # admin (view-all only) was excluded and could not be sent files.
      expect(User.can_receive_secure_files).to include(admin)
    end
    it 'excludes a user with neither permission' do
      expect(User.can_receive_secure_files).not_to include(sender)
    end
  end

  # received_by backs the "Received" list. Unlike viewable_by, the view-all branch
  # was deliberately NOT carried over: it returns only files where you're the
  # recipient, for everyone. These tests pin that contract at the model level so a
  # mutation back to `all` (re-leaking every file into admins' Received list) goes
  # red here, not just in the request spec.
  describe '.received_by' do
    it 'returns only the files sent to an assigned recipient' do
      expect(GrdaWarehouse::SecureFile.received_by(recipient)).to contain_exactly(file)
    end

    it 'does not surface every file to a view-all admin, only their own received files' do
      received = create :secure_file, recipient_id: admin.id, sender_id: sender.id
      expect(GrdaWarehouse::SecureFile.received_by(admin)).to contain_exactly(received)
    end

    it 'returns nothing for a user without any secure-file permission' do
      expect(GrdaWarehouse::SecureFile.received_by(sender)).to be_empty
    end

    it 'excludes expired files from the recipient\'s list' do
      expired = create :secure_file, recipient_id: recipient.id, sender_id: sender.id, created_at: 2.months.ago
      expect(GrdaWarehouse::SecureFile.received_by(recipient)).not_to include(expired)
    end
  end

  # clean_expired soft-deletes (acts_as_paranoid) only rows older than 1 month;
  # current files must survive. Guards the retention path against an over-broad
  # `expired` scope deleting live files.
  describe '.clean_expired' do
    it 'soft-deletes expired files and leaves current files intact' do
      expired = create :secure_file, recipient_id: recipient.id, sender_id: sender.id, created_at: 2.months.ago

      GrdaWarehouse::SecureFile.clean_expired

      expect(GrdaWarehouse::SecureFile.find_by(id: expired.id)).to be_nil
      expect(GrdaWarehouse::SecureFile.find_by(id: file.id)).to be_present
    end
  end
end
