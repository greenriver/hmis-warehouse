require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwentyTwo, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwentyTwo::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q22a1: Length of Participation – CoC Projects' do
  end

  describe 'Q22a2: Length of Participation – ESG Projects' do
  end

  describe 'Q22b: Average and Median Length of Participation in Days' do
  end

  describe 'Q22c: Length of Time between Project Start Date and Housing Move-in Date' do
  end

  describe 'Q22e: Length of Time Prior to Housing - based on 3.917 Date Homelessness Started' do
  end
end
