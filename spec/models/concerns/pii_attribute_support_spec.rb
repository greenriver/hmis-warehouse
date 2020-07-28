require 'rails_helper'

RSpec.describe PIIAttributeSupport, :pii, type: :model do
  let(:person) { TestPerson.new }
  let(:fetched_person) { TestPerson.first }

  # Want to test for encryption-related exceptions being thrown
  before(:each) { Encryption::SoftFailEncryptor.pii_soft_failure = false }

  before(:each) do
    TestPerson.allow_pii!
    TestPerson.current_pii_key = SecureRandom.hex(16)
    person.first_name = 'Larry'
    person.email = 'larry@example.com'
    person.hair = 'brown'
    person.save!
    expect(TestPerson.count).to be 1
  end

  it 'should work' do
    expect(fetched_person.first_name).to eq 'Larry'
    expect(fetched_person.encrypted_first_name).to_not eq 'Larry'
    expect(fetched_person.read_attribute(:first_name)).to_not eq 'Larry'
  end

  it 'should break with key rotation' do
    TestPerson.current_pii_key = SecureRandom.hex(16)
    expect { fetched_person.first_name }.to raise_error(OpenSSL::Cipher::CipherError)

    Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end

  it 'should break with invalid key' do
    TestPerson.current_pii_key = SecureRandom.hex(2)
    expect { fetched_person.first_name }.to raise_error(ArgumentError)

    Encryption::SoftFailEncryptor.pii_soft_failure = true

    expect(fetched_person.first_name).to eq('[REDACTED]')
  end
end
