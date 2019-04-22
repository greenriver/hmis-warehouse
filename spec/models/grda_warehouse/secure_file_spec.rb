require 'rails_helper'

RSpec.describe GrdaWarehouse::SecureFile, type: :model do
  let(:empty_role) { create :role }
  let(:secure_file_recipient) { create :secure_file_recipient }
  let(:secure_file_admin) { create :secure_file_admin }
  let(:sender) { create :user, roles: [empty_role] }
  let(:recipient) { create :user, roles: [secure_file_recipient] }
  let(:admin) { create :user, roles: [secure_file_admin] }
  let!(:file) { create :secure_file, recipient_id: recipient.id, sender_id: sender.id }
  let!(:file2) { create :secure_file }

  describe 'secure files have appropriate permissions' do
    it 'senders with no roles can\'t see the file after upload' do
      expect(GrdaWarehouse::SecureFile.visible_by?(sender).count).to eq 0
    end
    it 'recipient can see one upload' do
      expect(GrdaWarehouse::SecureFile.visible_by?(recipient).count).to eq 1
    end
    it 'recipient can see the upload' do
      expect(GrdaWarehouse::SecureFile.visible_by?(recipient).first.id).to eq file.id
    end
    it 'admin can see both files' do
      expect(GrdaWarehouse::SecureFile.visible_by?(admin).count).to eq 2
    end
  end
end
