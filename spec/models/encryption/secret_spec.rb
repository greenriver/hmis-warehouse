###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Encryption::Secret, type: :model do
  before(:all) do
    GrdaWarehouseBase.connection.execute(<<~SQL)
      CREATE TEMPORARY TABLE client_for_testing (
        id serial,
        "FirstName" character varying,
        "encrypted_FirstName" character varying,
        "encrypted_FirstName_iv" character varying
      )
    SQL
  end

  before(:all) { Encryption::Util.new.init! }

  before(:each) { client_class.allow_pii! }

  let(:subject) { Encryption::Secret }

  let(:client_class) do
    Class.new(GrdaWarehouseBase) do |k|
      k.table_name = 'client_for_testing'
      include PIIAttributeSupport
      attr_pii :FirstName
    end
  end

  let(:client) { client_class.new(FirstName: 'Jim') }

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

      client_class.find_each do |client|
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
      if client_class.column_names.include?('FirstName')
        expect(client.read_attribute(:FirstName)).to be_nil
      end
    end

    it 'should retain original cleartext value' do
      expect(client.FirstName).to eq('Jim')
    end
  end
end
