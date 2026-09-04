###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  def new_policy(permissions = {})
    default_permissions = {
      can_view_name?: false,
      can_view_photo?: false,
      can_view_full_dob?: false,
      can_view_full_ssn?: false,
      can_view_partial_ssn?: true,
      can_view_hiv_status?: false,
    }

    # Convert string/symbol keys to method names with question marks
    normalized_permissions = permissions.transform_keys do |key|
      key.to_s.end_with?('?') ? key.to_sym : "#{key}?".to_sym
    end

    instance_double(
      'GrdaWarehouse::AuthPolicies::SourceClientPolicy',
      default_permissions.merge(normalized_permissions),
    )
  end

  context('pii with view name permission') do
    let(:policy) { new_policy(can_view_name: true) }
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
    it('still redacts ssn and dob, which this policy does not grant') do
      expect(pii.ssn).to eq(masked_ssn)
      expect(pii.dob).to be_nil
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
    it('still redacts name and ssn, which this policy does not grant') do
      expect(pii.first_name).to eq('Name Redacted')
      expect(pii.ssn).to eq(masked_ssn)
    end
  end

  context('pii with view hiv status permission') do
    let(:policy) { new_policy(can_view_hiv_status: true) }

    it('displays viewable hiv status') do
      actual = GrdaWarehouse::PiiProvider.viewable_hiv_status('Y', policy: policy)
      expect(actual).to eq('Y')
    end
  end

  context('pii with view photo permission') do
    let(:policy) { new_policy(can_view_photo: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays image') { expect(pii.image).to eq(pii_attributes[:image]) }
    it('still redacts name, which this policy does not grant') do
      expect(pii.first_name).to eq('Name Redacted')
    end
  end

  context('pii with vew ssn permission') do
    let(:policy) { new_policy(can_view_full_ssn: true) }
    let(:pii) { GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_attributes) }

    it('displays ssn') { expect(pii.ssn).to eq(pii_attributes[:ssn]) }
    it('displays force-masked ssn') { expect(pii.ssn(force_mask: true)).to eq(masked_ssn) }
    it('still redacts name and dob, which this policy does not grant') do
      expect(pii.first_name).to eq('Name Redacted')
      expect(pii.dob).to be_nil
    end

    it 'still shows the full ssn even if can_view_partial_ssn? is (incorrectly) false -- full access implies partial' do
      full_only_policy = new_policy(can_view_full_ssn: true, can_view_partial_ssn: false)
      pii = GrdaWarehouse::PiiProvider.from_attributes(policy: full_only_policy, **pii_attributes)
      expect(pii.ssn).to eq(pii_attributes[:ssn])
    end
  end

  context('pii without permissions') do
    let(:policy) { new_policy }
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
    it('redacts viewable hiv status') do
      actual = GrdaWarehouse::PiiProvider.viewable_hiv_status('Y', policy: policy)
      expect(actual).to eq('Redacted')
    end
  end

  describe '.restrict' do
    let(:policy) { new_policy(can_view: true, can_view_name: true, can_view_full_ssn: true, can_view_full_dob: true, can_view_photo: true, can_view_hiv_status: true) }

    it 'returns the original policy unchanged when not restricted' do
      expect(GrdaWarehouse::PiiProvider.restrict(policy, restricted: false)).to eq(policy)
    end

    context 'when restricted' do
      subject(:restricted_policy) { GrdaWarehouse::PiiProvider.restrict(policy, restricted: true) }

      it 'preserves general visibility' do
        expect(restricted_policy.can_view?).to eq(true)
      end

      it 'redacts name, ssn, dob, photo, and hiv status regardless of the underlying policy' do
        expect(restricted_policy.can_view_name?).to eq(false)
        expect(restricted_policy.can_view_full_ssn?).to eq(false)
        expect(restricted_policy.can_view_full_dob?).to eq(false)
        expect(restricted_policy.can_view_photo?).to eq(false)
        expect(restricted_policy.can_view_hiv_status?).to eq(false)
      end

      it 'blocks the partial (masked) SSN too -- restricted means no SSN at all' do
        expect(restricted_policy.can_view_partial_ssn?).to eq(false)

        pii = GrdaWarehouse::PiiProvider.from_attributes(policy: restricted_policy, **pii_attributes)
        expect(pii.ssn).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      end

      it 'still shows blank rather than "Redacted" when the client has no SSN' do
        pii = GrdaWarehouse::PiiProvider.from_attributes(policy: restricted_policy, **pii_attributes.merge(ssn: nil))
        expect(pii.ssn).to be_nil
      end
    end

    context 'when restricted and the wrapped policy denies general visibility' do
      let(:policy) { new_policy(can_view: false, can_view_name: true, can_view_full_ssn: true, can_view_full_dob: true, can_view_photo: true, can_view_hiv_status: true) }
      subject(:restricted_policy) { GrdaWarehouse::PiiProvider.restrict(policy, restricted: true) }

      it 'still delegates can_view? to the wrapped policy' do
        expect(restricted_policy.can_view?).to eq(false)
      end
    end
  end
end
