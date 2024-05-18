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
    }
  end
  let(:masked_ssn) { 'XXX-XX-6789' }

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
  end

  context('pii with view dob permission') do
    let(:policy) { new_policy(can_view_full_dob: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays dob') { expect(pii.dob).to eq(pii_attributes[:dob]) }
    it('displays age') { expect(pii.age).to eq(pii_age) }
    it('displays dob over age') { expect(pii.dob_or_age).to eq(pii_attributes[:dob].to_fs) }
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
    it('redacts dob') { expect(pii.dob).to be_nil }
    it('masks ssn') { expect(pii.ssn).to eq(masked_ssn) }
    it('displays age over dob') { expect(pii.dob_or_age).to eq(pii_age.to_s) }
    # age is always shown
    it('displays age') { expect(pii.age).to eq(pii_age) }
    it('displays dob year and age') do
      expected = "#{pii_attributes[:dob].year} (#{pii_age})"
      expect(pii.dob_and_age).to eq(expected)
    end
  end
end
