###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request with invalid UTF-8 params', type: :request do
  it 'reproduces the ArgumentError: invalid byte sequence in UTF-8' do
    # The goal is to have a parameter key that is not valid UTF-8.
    # The byte 0xFF is an invalid UTF-8 byte. When part of a URL, it
    # would be percent-encoded as %FF. When Rails parses this, it will
    # create a parameter key with an invalid byte sequence.
    #
    # This test confirms the utf8-cleaner gem is correctly sanitizing URL input
    invalid_query_string = '%FF=exploit'

    # confirmed manually that this does raise without the gem installed
    expect do
      get "/?#{invalid_query_string}"
    end.to_not raise_error
    # end.to raise_error(ArgumentError, 'invalid byte sequence in UTF-8')
  end
end
