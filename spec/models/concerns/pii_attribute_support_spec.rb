require 'rails_helper'

RSpec.describe PIIAttributeSupport, :pii, type: :model do
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
        encrypted_first_name_iv character varying,
        email character varying,
        hair character varying
      )
    SQL
  end

  # Turn PII encryption on for the spec
  before(:each) { allow(Encryption::Util).to receive(:encryption_enabled?) { true } }

  # Want to test for encryption-related exceptions being thrown
  before(:each) { Encryption::SoftFailEncryptor.pii_soft_failure = false }

  before(:each) do
    person_class.allow_pii!
    person_class.current_pii_key = SecureRandom.hex(16)
    person.first_name = 'Larry'
    person.email = 'larry@example.com'
    person.hair = 'brown'
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

    Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end

  it 'should break with invalid key' do
    person_class.current_pii_key = SecureRandom.hex(2)
    expect { fetched_person.first_name }.to raise_error(ArgumentError)

    Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end

  describe "pluck functionality" do
    it "should work for various ways of passing params" do
      expect(person_class.pluck(:email).length).to eq(1)
      expect(person_class.pluck([:email]).length).to eq(1)
      expect(person_class.pluck(:email, :hair).length).to eq(1)
      expect(person_class.pluck([:email, :hair]).length).to eq(1)
      expect(person_class.pluck(:first_name).length).to eq(1)
    end

    it "should work for unencrypted" do
      expect(person_class.pluck(:email)).to eq(['larry@example.com'])
    end

    it "should work for sets of columns for unencrypted" do
      expect(person_class.pluck(:email, :hair)).to eq([['larry@example.com', 'brown']])
    end

    it "should work for encrypted" do
      expect(person_class.pluck(:first_name)).to eq(['Larry'])
    end

    it "should work for mix of encrypted and unencrypted" do
      expect(person_class.pluck(:first_name, :email, :hair)).to eq([['Larry', 'larry@example.com', 'brown']])
      expect(person_class.pluck(:email, :first_name, :hair)).to eq([['larry@example.com', 'Larry', 'brown']])
      expect(person_class.pluck(:email, :hair, :first_name)).to eq([['larry@example.com', 'brown', 'Larry']])
    end
  end
end
