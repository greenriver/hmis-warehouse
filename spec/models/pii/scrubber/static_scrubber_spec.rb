###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pii::Scrubber::StaticScrubber do
  let(:client1) do
    create(
      :grda_warehouse_hud_client,
      FirstName: 'John',
      MiddleName: 'Q',
      LastName: 'Public',
      SSN: '123456789',
      DOB: Date.new(2007, 5, 1),
    )
  end
  let(:client2) do
    create(
      :grda_warehouse_hud_client,
      FirstName: 'Jane',
      MiddleName: '',
      LastName: 'Doe',
      SSN: '987654321',
      DOB: Date.new(2008, 10, 17),
    )
  end

  def scrubbed_values(fields)
    fields.filter(&:scrubbed?).to_h { |f| [f.name, f.scrubbed_value] }
  end

  it 'replaces each present field with its placeholder, keyed to the record id' do
    fields1 = Pii::Scrubber::PiiAttribute.from_record(client1)
    fields2 = Pii::Scrubber::PiiAttribute.from_record(client2)

    described_class.new.perform(fields1 + fields2)

    expect(scrubbed_values(fields1)).to eq(
      FirstName: "FirstName#{client1.id}",
      MiddleName: "MiddleName#{client1.id}",
      LastName: "LastName#{client1.id}",
      SSN: '999000000',
      DOB: Date.new(2005, 1, 1),
    )
    expect(scrubbed_values(fields2)).to eq(
      FirstName: "FirstName#{client2.id}",
      LastName: "LastName#{client2.id}",
      SSN: '999000000',
      DOB: Date.new(2010, 1, 1),
    )
  end

  describe 'DOB' do
    include ActiveSupport::Testing::TimeHelpers

    def dob_field(record)
      Pii::Scrubber::PiiAttribute.new(name: :DOB, type: :dob, required: false, level: 2, record: record)
    end

    it 'rounds down instead of up when rounding up would be after today' do
      field = dob_field(build(:grda_warehouse_hud_client, DOB: Date.new(2028, 2, 1)))

      travel_to(Date.new(2028, 6, 1)) { described_class.new.perform([field]) }

      expect(field.scrubbed_value).to eq(Date.new(2025, 1, 1))
    end

    it 'rounds a DOB stored as a string' do
      field = dob_field(HmisCsvTwentyTwentySix::Loader::Client.new(DOB: '2008-10-17'))

      described_class.new.perform([field])

      expect(field.scrubbed_value).to eq(Date.new(2010, 1, 1))
    end

    it 'leaves an unparseable DOB for the later scrubbers' do
      field = dob_field(HmisCsvTwentyTwentySix::Loader::Client.new(DOB: '10/17/2008'))

      described_class.new.perform([field])

      expect(field.scrubbed?).to be(false)
    end
  end

  it 'leaves a field without a static placeholder for the later scrubbers' do
    unsupported_field = Pii::Scrubber::PiiAttribute.new(name: :FirstName, type: :free_text, required: false, level: 4, record: client1)

    described_class.new.perform([unsupported_field])

    expect(unsupported_field.scrubbed?).to be(false)
  end
end
