# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::WorkflowExecution::Instance, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_workflow_execution_instance, template: create(:hmis_workflow_definition_template, data_source: ds1)) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(updated_at: Time.current + 1.minute) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
