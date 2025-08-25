# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::WorkflowDefinition::Flow, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    lambda do
      template = create(:hmis_workflow_definition_template, data_source: ds1)
      source = create(:hmis_workflow_definition_start_event, template: template)
      target = create(:hmis_workflow_definition_end_event, template: template)
      create(:hmis_workflow_definition_flow, template: template, source_node: source, target_node: target)
    end
  end

  # Flow has paper_trail and acts_as_paranoid
  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(position: (record.position || 0) + 1) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
