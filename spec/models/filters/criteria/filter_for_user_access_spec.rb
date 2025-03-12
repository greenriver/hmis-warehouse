# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForUserAccess do
  include_context 'filter criteria setup'

  let(:filter) { ::Filters::FilterBase.new(user_id: user.id) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:viewable_project) { create_project }
  let!(:restricted_project) { create_project(confidential: true) }

  let!(:enrollments) do
    [
      create_enrollment_for_client(create(:hud_client), project_id: viewable_project.ProjectID),
      create_enrollment_for_client(create(:hud_client), project_id: restricted_project.ProjectID),
    ]
  end

  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    it 'returns only enrollments from viewable projects' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end
  end
end
