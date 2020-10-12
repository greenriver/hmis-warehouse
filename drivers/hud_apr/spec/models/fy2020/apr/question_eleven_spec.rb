require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionEleven, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionEleven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q11: Age' do
  end
end
