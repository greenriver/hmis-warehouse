require 'rails_helper'

RSpec.describe 'GrdaWarehouse::PiiProvider', type: :model do
  let(:today) { Date.current }
  let(:pii_age) { 20 }
  let(:pii_attributes) do
    {
      first_name: 'First',
      last_name: 'Last',
      middle_name: 'Middle',
      dob: today - pii_age.years,
      ssn: '123-45-6789',
      # random jpeg data > 100 chars
      image: "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01\x01\x01\x00\x60\x00\x60\x00\x00\xFF\xE1\x00\x16\x45\x78\x69\x66\x00\x00\x4D\x4D\x00\x2A\x00\x00\x00\x08\x00\x01\x01\x12\x00\x03\x00\x00\x00\x01\x00\x01\x00\x00\xFF\xDB\x00\x43\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\x09\x09\x08\x0A\x0C\x14\x0D\x0C\x0B\x0B\x0C\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C\x20\x24\x2E\x27\x20\x22\x2C\x23\x1C\x1C\x28\x37\x29\x2C\x30\x31\x34",
    }
  end
  let(:masked_ssn) { 'XXX-XX-6789' }
  let(:age_with_year_only) { "#{pii_attributes[:dob].year} (#{pii_age})" }

  def new_policy(**perms)
    # roles and policy have the same shape
    build(:role, **perms)
  end

  context('pii with view name permission') do
    let(:policy) { new_policy(can_view_client_name: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays first_name') { expect(pii.first_name).to eq(pii_attributes[:first_name]) }
    it('displays last_name') { expect(pii.last_name).to eq(pii_attributes[:last_name]) }
    it('displays middle_name') { expect(pii.middle_name).to eq(pii_attributes[:middle_name]) }
    it('displays brief_name')  do
      expected = pii_attributes.values_at(:first_name, :last_name).join(' ')
      expect(pii.brief_name).to eq(expected)
    end
    it('displays full_name') do
      expected = pii_attributes.values_at(:first_name, :middle_name, :last_name).join(' ')
      expect(pii.full_name).to eq(expected)
    end
    it('displays viewable name') do
      actual = GrdaWarehouse::PiiProvider.viewable_name(pii_attributes[:first_name], policy: policy)
      expect(actual).to eq(pii_attributes[:first_name])
    end
  end

  context('pii with view dob permission') do
    let(:policy) { new_policy(can_view_full_dob: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays dob') { expect(pii.dob).to eq(pii_attributes[:dob]) }
    it('displays age') { expect(pii.age).to eq(pii_age) }
    it('displays dob over age') { expect(pii.dob_or_age).to eq(pii_attributes[:dob].to_fs) }
    it('displays viewable dob') do
      actual = GrdaWarehouse::PiiProvider.viewable_dob(pii_attributes[:dob], policy: policy)
      expect(actual).to eq(pii_attributes[:dob])
    end
    it('displays dob year and age') do
      expected = "#{pii_attributes[:dob]} (#{pii_age})"
      expect(pii.dob_and_age).to eq(expected)
    end
    it('displays force-masked dob') { expect(pii.dob_and_age(force_year_only: true)).to eq(age_with_year_only) }
  end

  context('pii with view photo permission') do
    let(:policy) { new_policy(can_view_client_photo: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays image') { expect(pii.image).to eq(pii_attributes[:image]) }
  end

  context('pii with vew ssn permission') do
    let(:policy) { new_policy(can_view_full_ssn: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays ssn') { expect(pii.ssn).to eq(pii_attributes[:ssn]) }
    it('displays force-masked ssn') { expect(pii.ssn(force_mask: true)).to eq(masked_ssn) }
  end

  context('pii without permissions') do
    let(:policy) { GrdaWarehouse::AuthPolicies::DenyPolicy.instance }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }
    let(:name_redacted) { 'Name Redacted' }
    it('redacts first_name') { expect(pii.first_name).to eq(name_redacted) }
    it('redacts last_name') { expect(pii.last_name).to eq(name_redacted) }
    it('redacts middle_name') { expect(pii.middle_name).to eq(name_redacted) }
    it('redacts brief_name') { expect(pii.brief_name).to eq(name_redacted) }
    it('redacts full_name') { expect(pii.full_name).to eq(name_redacted) }
    it('redacts image') { expect(pii.image).to be_blank }
    it('redacts dob') { expect(pii.dob).to be_nil }
    it('masks ssn') { expect(pii.ssn).to eq(masked_ssn) }
    it('displays age over dob') { expect(pii.dob_or_age).to eq(pii_age.to_s) }
    # age is always shown
    it('displays age') { expect(pii.age).to eq(pii_age) }
    it('displays dob year and age') do
      expect(pii.dob_and_age).to eq(age_with_year_only)
    end
    it('redacts viewable dob') do
      actual = GrdaWarehouse::PiiProvider.viewable_dob(pii_attributes[:dob], policy: policy)
      expect(actual).to eq('Redacted')
    end
    it('redacts viewable name') do
      actual = GrdaWarehouse::PiiProvider.viewable_name(pii_attributes[:first_name], policy: policy)
      expect(actual).to eq('Redacted')
    end
  end
end
