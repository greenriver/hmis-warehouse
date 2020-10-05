require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwentyOne, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwentyOne::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q21: Health Insurance' do
  end
end
