###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Encryption::Secret, :pii, type: :model do
  before(:each) { allow(Encryption::Util).to receive(:encryption_enabled?) { true } }
  before(:each) { TestClient.allow_pii! }

  let(:subject) { Encryption::Secret }
  let(:client) { TestClient.new(FirstName: 'Jim') }

  it 'should have a current key' do
    expect(subject.current.plaintext_key.length).to eq(32)
  end

  def save_and_rotate
    client.save!

    @original_encrypted_FirstName = client.encrypted_FirstName
    @original_encrypted_FirstName_iv = client.encrypted_FirstName_iv
    @original_encryption_key = Encryption::Secret.current.plaintext_key

    Encryption::Secret.current.rotate! do |old_secret, new_secret|
      old_key = old_secret.plaintext_key
      new_key = new_secret.plaintext_key

      TestClient.find_each do |client|
        client.rekey!(old_key, new_key)
      end
    end

    client.reload
  end

  context 'key rotation' do
    it 'should rotate without error' do
      save_and_rotate
    end

    it 'should change key' do
      expect(Encryption::Secret.current.plaintext_key).to_not eq(@original_encryption_key)
    end

    it 'should change database values' do
      expect(client.encrypted_FirstName).to_not eq(@original_encrypted_FirstName)
      expect(client.encrypted_FirstName_iv).to_not eq(@original_encrypted_FirstName_iv)
    end

    it 'should not touch cleartext column if it exists' do
      if TestClient.column_names.include?('FirstName')
        expect(client.read_attribute(:FirstName)).to be_nil
      end
    end

    it 'should retain original cleartext value' do
      expect(client.FirstName).to eq('Jim')
    end
  end
end
