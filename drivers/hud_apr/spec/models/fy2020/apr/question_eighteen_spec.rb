require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionEighteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionEighteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q18: Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status' do
  end
end
