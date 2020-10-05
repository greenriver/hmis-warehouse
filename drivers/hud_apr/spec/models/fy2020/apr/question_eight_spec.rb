require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionEight, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionEight::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q8a: Number of Households Served' do
  end

  describe 'Q8b: Point-in-Time Count of Households on the Last Wednesday' do
  end
end
