require 'rails_helper'

RSpec.describe PIIAttributeSupport, type: :model do
  let(:person_class) do
    Class.new(GrdaWarehouseBase) do |k|
      k.table_name = 'people_for_testing'
      include PIIAttributeSupport
      attr_pii :first_name
    end
  end

  let(:person) { person_class.new }
  let(:fetched_person) { person_class.first }

  before(:all) do
    GrdaWarehouseBase.connection.execute(<<~SQL)
      CREATE TEMPORARY TABLE people_for_testing (
        id serial,
        encrypted_first_name character varying,
        encrypted_first_name_iv character varying
      )
    SQL
  end

  before(:each) do
    GrdaWarehouse::Encryption::SoftFailEncryptor.pii_soft_failure = false
    person_class.allow_pii!
    person_class.current_pii_key = SecureRandom.hex(16)
    person.first_name = 'Larry'
    person.save!
    expect(person_class.count).to be 1
  end

  it 'should work' do
    expect(fetched_person.first_name).to eq 'Larry'
    expect(fetched_person.encrypted_first_name).to_not eq 'Larry'
    expect(fetched_person.read_attribute(:first_name)).to_not eq 'Larry'
  end

  it 'should break with key rotation' do
    person_class.current_pii_key = SecureRandom.hex(16)
    expect { fetched_person.first_name }.to raise_error(OpenSSL::Cipher::CipherError)

    GrdaWarehouse::Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end

  it 'should break with invalid key' do
    person_class.current_pii_key = SecureRandom.hex(2)
    expect { fetched_person.first_name }.to raise_error(ArgumentError)

    GrdaWarehouse::Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end
end
