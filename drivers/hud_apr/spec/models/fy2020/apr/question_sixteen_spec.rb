require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionSixteen, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionSixteen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q16: Cash Income - Ranges' do
  end
end
