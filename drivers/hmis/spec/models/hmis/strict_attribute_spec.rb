###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Hmis::StrictDecimal, type: :model do
  describe '#cast' do
    it 'casts valid decimal strings' do
      expect(Hmis::StrictDecimal.new.cast('123.45')).to eq(123.45)
      expect(Hmis::StrictDecimal.new.cast('0.0')).to eq(0.0)
      expect(Hmis::StrictDecimal.new.cast('-123.45')).to eq(-123.45)
      expect(Hmis::StrictDecimal.new.cast('500.')).to eq(500.0)
      expect(Hmis::StrictDecimal.new.cast('.5')).to eq(0.5)
    end

    it 'raises an error for invalid values' do
      expect { Hmis::StrictDecimal.new.cast('abc') }.to raise_error(ArgumentError)
      expect { Hmis::StrictDecimal.new.cast(Object.new) }.to raise_error(ArgumentError)
      expect { Hmis::StrictDecimal.new.cast({ 'foo': 'bar' }) }.to raise_error(ArgumentError)
    end

    it 'leaves nil alone' do
      expect(Hmis::StrictDecimal.new.cast(nil)).to eq(nil)
    end
  end
end

RSpec.describe Hmis::StrictInteger, type: :model do
  describe '#cast' do
    it 'casts valid integer strings' do
      expect(Hmis::StrictInteger.new.cast('123')).to eq(123)
      expect(Hmis::StrictInteger.new.cast('-123')).to eq(-123)
      expect(Hmis::StrictInteger.new.cast('500.0')).to eq(500)
    end

    it 'casts booleans to integer' do
      expect(Hmis::StrictInteger.new.cast(false)).to eq(0)
      expect(Hmis::StrictInteger.new.cast(true)).to eq(1)
    end

    it 'raises an error for invalid values' do
      expect { Hmis::StrictInteger.new.cast('123.45') }.to raise_error(ArgumentError)
      expect { Hmis::StrictInteger.new.cast('abc') }.to raise_error(ArgumentError)
      expect { Hmis::StrictInteger.new.cast(Object.new) }.to raise_error(ArgumentError)
      expect { Hmis::StrictInteger.new.cast({ 'foo': 'bar' }) }.to raise_error(ArgumentError)
    end

    it 'leaves nil alone' do
      expect(Hmis::StrictInteger.new.cast(nil)).to eq(nil)
    end
  end
end
