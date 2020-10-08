require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionTwentyFive, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2020::QuestionTwentyFive::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q25a: Number of Veterans' do
  end

  describe 'Q25b: Number of Veteran Households' do
  end

  describe 'Q25c: Gender – Veterans' do
  end

  describe 'Q25d: Age – Veterans' do
  end

  describe 'Q25e: Physical and Mental Health Conditions – Veterans' do
  end

  describe 'Q25f: Cash Income Category - Income Category - by Start and Annual /Exit Status – Veterans' do
  end

  describe 'Q25g: Type of Cash Income Sources – Veterans' do
  end

  describe 'Q25h: Type of Non-Cash Benefit Sources – Veterans' do
  end

  describe 'Q25i: Exit Destination – Veterans' do
  end
end
