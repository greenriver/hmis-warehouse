# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/shared_examples/versioning_and_paranoia'

RSpec.describe Hmis::WorkflowExecution::Step, type: :model do
  include_context 'hmis base setup'

  let(:build_record) do
    -> { create(:hmis_wfe_step) }
  end

  let(:update_attributes_for_versioning) do
    ->(record) { record.update!(available_at: Time.current + 5.minutes) }
  end

  describe 'paranoia' do
    it_behaves_like 'paranoid model'
  end

  describe 'paper trail' do
    it_behaves_like 'versioned model'
  end
end
