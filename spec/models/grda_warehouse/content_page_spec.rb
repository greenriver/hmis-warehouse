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

    it 'validates slug format with representative cases' do
      expect(build(:content_page, slug: 'with-dashes')).not_to be_valid
      expect(build(:content_page, slug: 'valid_slug_123')).to be_valid
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
