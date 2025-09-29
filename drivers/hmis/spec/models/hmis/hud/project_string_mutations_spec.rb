# frozen_string_literal: false

require 'rails_helper'

RSpec.describe Hmis::Hud::Project, type: :model do
  let(:data_source) { create(:hmis_data_source) }

  describe '.matching_search_term scope string mutations' do
    let!(:project) { create(:hmis_hud_project, ProjectName: 'Test Housing Project', data_source: data_source) }

    it 'mutates search term with strip! operation' do
      # Test the strip! operation from line 135: search_term.strip!
      search_term = '  housing project  '

      result = Hmis::Hud::Project.matching_search_term(search_term)

      # Should have processed the search term (including strip!)
      expect(result).to include(project)
    end

    it 'handles search term with special characters' do
      search_term = 'Test!@#Housing$%^Project'

      result = Hmis::Hud::Project.matching_search_term(search_term)

      # Should handle the string processing and splitting
      expect(result).to include(project)
    end

    it 'returns none for blank search term' do
      result = Hmis::Hud::Project.matching_search_term('')

      expect(result.to_a).to be_empty
    end
  end
end
