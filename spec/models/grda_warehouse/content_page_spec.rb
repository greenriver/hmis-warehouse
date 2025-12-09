###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ContentPage, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      page = build(:content_page)
      expect(page).to be_valid
    end

    it 'requires a title' do
      page = build(:content_page, title: nil)
      expect(page).not_to be_valid
      expect(page.errors[:title]).to be_present
    end

    it 'requires content' do
      page = build(:content_page, content: nil)
      expect(page).not_to be_valid
      expect(page.errors[:content]).to be_present
    end

    it 'requires a unique slug' do
      create(:content_page, slug: 'unique_slug')
      page = build(:content_page, slug: 'unique_slug')
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it 'validates slug format - only lowercase letters, numbers, underscores' do
      invalid_slugs = ['UPPERCASE', 'with-dashes', 'with spaces', 'special@chars']
      invalid_slugs.each do |slug|
        page = build(:content_page, slug: slug)
        expect(page).not_to be_valid, "Expected slug '#{slug}' to be invalid"
      end
    end

    it 'accepts valid slug formats' do
      valid_slugs = ['lowercase', 'with_underscores', 'with123numbers', 'mixed_123']
      valid_slugs.each do |slug|
        page = build(:content_page, slug: slug)
        expect(page).to be_valid, "Expected slug '#{slug}' to be valid"
      end
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from title if not provided' do
      page = create(:content_page, title: 'My Test Page', slug: nil)
      expect(page.slug).to eq('my_test_page')
    end

    it 'does not overwrite an explicitly provided slug' do
      page = create(:content_page, title: 'My Test Page', slug: 'custom_slug')
      expect(page.slug).to eq('custom_slug')
    end

    it 'handles special characters in title when generating slug' do
      page = create(:content_page, title: 'Terms & Conditions!', slug: nil)
      expect(page.slug).to eq('terms_conditions')
    end
  end

  describe '#to_param' do
    it 'returns the slug for URL generation' do
      page = create(:content_page, slug: 'my_page')
      expect(page.to_param).to eq('my_page')
    end
  end

  describe 'associations' do
    it 'can have compliance requirements' do
      page = create(:content_page)
      requirement = create(:compliance_requirement, content_page: page)
      expect(page.compliance_requirements).to include(requirement)
    end

    it 'prevents deletion when linked to compliance requirements' do
      page = create(:content_page)
      create(:compliance_requirement, content_page: page)
      expect { page.destroy }.not_to change(GrdaWarehouse::ContentPage, :count)
      expect(page.errors[:base]).to be_present
    end
  end

  describe 'scopes' do
    it '.ordered sorts by title then id' do
      create(:content_page, title: 'Banana')
      create(:content_page, title: 'Apple')
      create(:content_page, title: 'Cherry')

      expect(GrdaWarehouse::ContentPage.ordered.pluck(:title)).to eq(['Apple', 'Banana', 'Cherry'])
    end
  end
end
