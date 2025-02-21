require 'rails_helper'

RSpec.describe Filters::Criteria do
  let(:user) { create(:user) }
  let(:input) { ::Filters::FilterBase.new(user_id: user.id) }
  let(:config) { Filters::Criteria::Configuration.new }

  describe '.factory' do
    it 'creates the appropriate criteria class' do
      criteria = described_class.factory(:filter_for_age, input: input, config: config)
      expect(criteria).to be_a(Filters::Criteria::FilterForAge)
    end
  end

  describe '.classes_for_tags' do
    it 'returns criteria classes matching all given tags' do
      classes = described_class.classes_for_tags([:warehouse, :client])
      expect(classes).to include(Filters::Criteria::FilterForAge)
      expect(classes).not_to include(Filters::Criteria::FilterForProjectType)
    end
  end
end
