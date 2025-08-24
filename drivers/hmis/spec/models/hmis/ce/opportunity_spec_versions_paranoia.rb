# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::Ce::Opportunity, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    lambda do
      template = create(:hmis_workflow_definition_template, data_source: ds1)
      project = create(:hmis_hud_project, data_source: ds1)
      create(:hmis_ce_opportunity, workflow_template: template, project: project, data_source: ds1)
    end
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(name: "Updated #{record.name}") }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
