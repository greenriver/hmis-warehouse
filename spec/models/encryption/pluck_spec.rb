require 'rails_helper'

RSpec.describe Encryption::Pluck, :pii, type: :model do
  let(:person) { TestPerson.new }
  let(:fetched_person) { TestPerson.first }

  before(:all) do
    load "lib/encrypted_pluck/monkey_patch.rb"
  end

  before(:each) do
    TestPerson.allow_pii!
    TestPerson.current_pii_key = SecureRandom.hex(16)
    person.first_name = 'Larry'
    person.email = 'larry@example.com'
    person.hair = 'brown'
    person.save!

    person.test_addresses.create!({
      street: '101 main st'
    })

    expect(TestPerson.count).to be 1
    expect(TestAddress.count).to be 1
  end

  describe "pluck functionality (encryption allowed)" do
    before(:each) { TestPerson.allow_pii!  }

    it "should not break unrelated features in monkey-patched module" do
      expect(TestAddress.ids.length).to be(1)
      expect(TestAddress.count).to be(1)
    end

    it "should work for unencrypted" do
      expect(TestPerson.pluck('email')).to eq(['larry@example.com'])
      expect(TestPerson.pluck(:email)).to eq(['larry@example.com'])
      expect(TestPerson.pluck([:email])).to eq(['larry@example.com'])
      expect(TestPerson.pluck(['email'])).to eq(['larry@example.com'])
      expect(TestPerson.joins(:test_addresses).pluck(:email)).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(:email)).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:email])).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:email].as('the_email'))).to eq(['larry@example.com'])
    end

    it "should work for unencrypted null values" do
      person.update_attribute(:email, nil)
      expect(TestPerson.pluck('email')).to eq([nil])
      expect(TestPerson.pluck(:email)).to eq([nil])
      expect(TestPerson.pluck([:email])).to eq([nil])
      expect(TestPerson.pluck(['email'])).to eq([nil])
    end

    it "should work for sets of columns for unencrypted" do
      expect(TestPerson.pluck(:email, :hair)).to eq([['larry@example.com', 'brown']])
    end

    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck('first_name')).to eq([nil]) }
    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck(:first_name)).to eq([nil]) }
    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck([:first_name])).to eq([nil]) }
    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck(['first_name'])).to eq([nil]) }
    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck(TestPerson.arel_table[:first_name])).to eq([nil]) }
    it("should work for null encrypted simple plucks") { person.update_attribute(:first_name, nil);  expect(TestPerson.pluck(TestPerson.arel_table[:first_name].as('the_first_name'))).to eq([nil]) }

    it("should work for encrypted simple plucks") { expect(TestPerson.pluck('first_name')).to eq(['Larry']) }
    it("should work for encrypted simple plucks") { expect(TestPerson.pluck(:first_name)).to eq(['Larry']) }
    it("should work for encrypted simple plucks") { expect(TestPerson.pluck([:first_name])).to eq(['Larry']) }
    it("should work for encrypted simple plucks") { expect(TestPerson.pluck(['first_name'])).to eq(['Larry']) }
    it("should work for encrypted simple plucks") { expect(TestPerson.pluck(TestPerson.arel_table[:first_name])).to eq(['Larry']) }
    it("should work for encrypted simple plucks") { expect(TestPerson.pluck(TestPerson.arel_table[:first_name].as('the_first_name'))).to eq(['Larry']) }

    it("should work for encrypted joins") { expect(TestPerson.joins(:test_addresses).pluck(:first_name)).to eq(['Larry']) }
    it("should work for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(:first_name)).to eq(['Larry']) }
    it("should work for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:first_name])).to eq(['Larry']) }
    it("should work for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:first_name].as('the_first_name'))).to eq(['Larry']) }

    it "should work for mix of encrypted and unencrypted" do
      expect(TestPerson.pluck(:first_name, :email, :hair)).to eq([['Larry', 'larry@example.com', 'brown']])
      expect(TestPerson.pluck(:email, :first_name, :hair)).to eq([['larry@example.com', 'Larry', 'brown']])
      expect(TestPerson.pluck(:email, :hair, :first_name)).to eq([['larry@example.com', 'brown', 'Larry']])

      person.update_attributes!({
        email: nil,
        hair: nil,
        first_name: nil
      })

      expect(TestPerson.pluck(:email, :hair, :first_name)).to eq([[nil, nil, nil]])
    end
  end

  describe "pluck functionality (encryption NOT allowed)" do
    before(:each) { TestPerson.deny_pii!  }

    it "should work for unencrypted" do
      expect(TestPerson.pluck('email')).to eq(['larry@example.com'])
      expect(TestPerson.pluck(:email)).to eq(['larry@example.com'])
      expect(TestPerson.pluck([:email])).to eq(['larry@example.com'])
      expect(TestPerson.pluck(['email'])).to eq(['larry@example.com'])
      expect(TestPerson.joins(:test_addresses).pluck(:email)).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(:email)).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:email])).to eq(['larry@example.com'])
      expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:email].as('the_email'))).to eq(['larry@example.com'])
    end

    it "should work for sets of columns for unencrypted" do
      expect(TestPerson.pluck(:email, :hair)).to eq([['larry@example.com', 'brown']])
    end

    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck('first_name')).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck(:first_name)).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck([:first_name])).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck(['first_name'])).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck(TestPerson.arel_table[:first_name])).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted simple plucks") { expect(TestPerson.pluck(TestPerson.arel_table[:first_name].as('the_first_name'))).to eq(['[REDACTED]']) }

    it("should soft-fail for encrypted joins") { expect(TestPerson.joins(:test_addresses).pluck(:first_name)).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(:first_name)).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:first_name])).to eq(['[REDACTED]']) }
    it("should soft-fail for encrypted joins") { expect(TestAddress.joins(:test_person).pluck(TestPerson.arel_table[:first_name].as('the_first_name'))).to eq(['[REDACTED]']) }

    it "should soft-fail for mix of encrypted and unencrypted" do
      expect(TestPerson.pluck(:first_name, :email, :hair)).to eq([['[REDACTED]', 'larry@example.com', 'brown']])
      expect(TestPerson.pluck(:email, :first_name, :hair)).to eq([['larry@example.com', '[REDACTED]', 'brown']])
      expect(TestPerson.pluck(:email, :hair, :first_name)).to eq([['larry@example.com', 'brown', '[REDACTED]']])
    end
  end
end
