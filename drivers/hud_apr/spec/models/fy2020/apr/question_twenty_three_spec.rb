require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwentyThree, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwentyThree::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q23c: Exit Destination' do
  end
end
