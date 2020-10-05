require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwenty, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwenty::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q20a: Type of Non-Cash Benefit Sources' do
  end

  describe 'Q20b: Number of Non-Cash Benefit Sources' do
  end
end
