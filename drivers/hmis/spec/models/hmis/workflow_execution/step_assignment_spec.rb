# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::WorkflowExecution::StepAssignment, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_wfe_step_assignment) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(user: create(:hmis_user)) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
