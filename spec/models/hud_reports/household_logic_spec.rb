# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdLogic do
  describe '.calculate_household_type' do
    it 'returns :adults_and_children when both adults and children are present' do
      expect(described_class.calculate_household_type([40, 10])).to eq(:adults_and_children)
    end

    it 'returns :adults_only when only adults are present' do
      expect(described_class.calculate_household_type([40, 25])).to eq(:adults_only)
    end

    it 'returns :children_only when only children are present' do
      expect(described_class.calculate_household_type([10, 12])).to eq(:children_only)
    end

    it 'returns :unknown if any age is nil' do
      expect(described_class.calculate_household_type([40, nil])).to eq(:unknown)
    end

    it 'returns :unknown if ages are empty' do
      expect(described_class.calculate_household_type([])).to eq(:unknown)
    end
  end

  describe '.calculate_chronic_status' do
    let(:hoh) do
      {
        client_id: 1,
        entry_date: Date.parse('2020-01-01'),
        age: 40,
        chronic_status: true,
        chronic_detail: 'yes',
      }
    end

    let(:child) do
      {
        client_id: 2,
        entry_date: Date.parse('2020-01-01'),
        age: 10,
        chronic_status: false,
        chronic_detail: 'no',
      }
    end

    let(:members) { [hoh, child] }

    it 'inherits chronic status from HoH if they are chronic and entry dates match' do
      result = described_class.calculate_chronic_status(members, child, hoh)
      expect(result[:status]).to be true
      expect(result[:detail]).to eq('yes')
    end

    it 'inherits from another chronic adult if HoH is not chronic' do
      hoh[:chronic_status] = false
      hoh[:chronic_detail] = 'no'

      adult2 = {
        client_id: 3,
        entry_date: Date.parse('2020-01-01'),
        age: 35,
        chronic_status: true,
        chronic_detail: 'yes',
      }

      result = described_class.calculate_chronic_status([hoh, child, adult2], child, hoh)
      expect(result[:status]).to be true
      expect(result[:detail]).to eq('yes')
    end

    it 'uses own status for adults even if HoH is chronic' do
      adult2 = {
        client_id: 3,
        entry_date: Date.parse('2020-01-01'),
        age: 35,
        chronic_status: false,
        chronic_detail: 'no',
      }
      # Note: Legacy logic says if HoH is chronic, return HoH if entry dates match
      result = described_class.calculate_chronic_status([hoh, adult2], adult2, hoh)
      expect(result[:status]).to be true
    end

    it 'uses own status for adults if no other adult is chronic' do
      hoh[:chronic_status] = false
      adult2 = {
        client_id: 3,
        entry_date: Date.parse('2020-01-01'),
        age: 35,
        chronic_status: true,
        chronic_detail: 'yes',
      }
      result = described_class.calculate_chronic_status([hoh, adult2], adult2, hoh)
      expect(result[:status]).to be true
    end

    context 'when calculating PIT chronic status' do
      let(:hoh) do
        {
          client_id: 1,
          entry_date: Date.parse('2020-01-01'),
          age: 40,
          pit_chronic_status: false,
          pit_chronic_detail: 'no',
        }
      end

      let(:child) do
        {
          client_id: 2,
          entry_date: Date.parse('2020-01-01'),
          age: 10,
          pit_chronic_status: true,
          pit_chronic_detail: 'yes',
        }
      end

      it 'does not allow HoH to inherit from child' do
        result = described_class.calculate_chronic_status([hoh, child], hoh, hoh, chronic_status_key: :pit_chronic_status)
        expect(result[:status]).to be false
      end

      it 'allows child to inherit from another chronic adult' do
        hoh[:pit_chronic_status] = false
        adult2 = {
          client_id: 3,
          entry_date: Date.parse('2020-01-01'),
          age: 35,
          pit_chronic_status: true,
          pit_chronic_detail: 'yes',
        }

        result = described_class.calculate_chronic_status([hoh, child, adult2], child, hoh, chronic_status_key: :pit_chronic_status)
        expect(result[:status]).to be true
        expect(result[:detail]).to eq('yes')
      end
    end

    context 'with indeterminate (DK/R) data' do
      it 'inherits DK/R status from HoH for children' do
        hoh[:chronic_status] = false
        hoh[:chronic_detail] = 'dk_or_r'
        child[:chronic_status] = false
        child[:chronic_detail] = 'no'

        result = described_class.calculate_chronic_status(members, child, hoh)
        expect(result[:status]).to be false
        expect(result[:detail]).to eq('dk_or_r')
      end

      it 'inherits from HoH if child has missing status' do
        hoh[:chronic_status] = true
        hoh[:chronic_detail] = 'yes'
        child[:chronic_status] = false
        child[:chronic_detail] = 'missing'

        result = described_class.calculate_chronic_status(members, child, hoh)
        expect(result[:status]).to be true
        expect(result[:detail]).to eq('yes')
      end
    end
  end

  describe '.calculate_is_parenting_youth' do
    let(:youth_hoh) { { age: 20, relationship_to_hoh: 1 } }
    let(:child) { { age: 2, relationship_to_hoh: 2 } }
    let(:members) { [youth_hoh, child] }

    it 'returns true for a youth household with children' do
      expect(described_class.calculate_is_parenting_youth(youth_hoh, members)).to be true
    end

    it 'returns false if there is a member over 24' do
      adult = { age: 25, relationship_to_hoh: 3 }
      expect(described_class.calculate_is_parenting_youth(youth_hoh, [youth_hoh, child, adult])).to be false
    end

    it 'returns false if there are no children (relationship 2)' do
      spouse = { age: 20, relationship_to_hoh: 3 }
      expect(described_class.calculate_is_parenting_youth(youth_hoh, [youth_hoh, spouse])).to be false
    end

    it 'considers youth up to age 24 as children for parenting youth status' do
      # APR nuance: child can be up to 24 in a youth household
      older_child = { age: 24, relationship_to_hoh: 2 }
      expect(described_class.calculate_is_parenting_youth(youth_hoh, [youth_hoh, older_child])).to be true
    end
  end

  describe '.calculate_move_in_date' do
    let(:hoh) do
      {
        entry_date: Date.parse('2020-01-01'),
        move_in_date: Date.parse('2020-02-01'),
      }
    end

    let(:member) do
      {
        entry_date: Date.parse('2020-01-01'),
        exit_date: nil,
      }
    end

    it 'uses members own move-in date if valid' do
      member[:move_in_date] = Date.parse('2020-03-01')
      expect(described_class.calculate_move_in_date(member, hoh)).to eq(Date.parse('2020-03-01'))
    end

    it 'inherits HoH move-in date if member was present' do
      expect(described_class.calculate_move_in_date(member, hoh)).to eq(Date.parse('2020-02-01'))
    end

    it 'uses entry date if member joined after HoH moved in' do
      member[:entry_date] = Date.parse('2020-03-01')
      expect(described_class.calculate_move_in_date(member, hoh)).to eq(Date.parse('2020-03-01'))
    end

    it 'returns nil if HoH has no move-in date' do
      hoh[:move_in_date] = nil
      expect(described_class.calculate_move_in_date(member, hoh)).to eq(nil)
    end
  end

  describe '.calculate_date_to_street' do
    let(:hoh) do
      {
        entry_date: Date.parse('2020-01-01'),
        date_to_street: Date.parse('2019-12-01'),
      }
    end

    let(:member) do
      {
        entry_date: Date.parse('2020-01-01'),
        age: 10,
        dob: Date.parse('2010-01-01'),
      }
    end

    it 'uses members own date_to_street if present' do
      member[:date_to_street] = Date.parse('2019-12-15')
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(Date.parse('2019-12-15'))
    end

    it 'caps own date_to_street at DOB' do
      member[:date_to_street] = Date.parse('2009-12-15') # Before birth
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(member[:dob])
    end

    it 'inherits from HoH if child under 17 and same entry date' do
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(hoh[:date_to_street])
    end

    it 'caps inherited date_to_street at DOB' do
      hoh[:date_to_street] = Date.parse('2000-01-01') # Long before child birth
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(member[:dob])
    end

    it 'does not inherit if member entry date differs' do
      member[:entry_date] = Date.parse('2020-01-02')
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(nil)
    end

    it 'does not inherit if member is over 17' do
      member[:age] = 18
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(nil)
    end

    it 'returns nil if HoH has no date_to_street' do
      hoh[:date_to_street] = nil
      expect(described_class.calculate_date_to_street(member, hoh)).to eq(nil)
    end

    it 'returns nil if HoH is missing' do
      expect(described_class.calculate_date_to_street(member, nil)).to eq(nil)
    end
  end
end
