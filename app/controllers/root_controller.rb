###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RootController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    already_there = current_user&.my_root_path == root_path
    return redirect_to(current_user.my_root_path) if current_user && !already_there

    # The sign-in views are HTML-only; other formats get a 406 (UnknownFormat)
    respond_to(&:html)
  end
end
