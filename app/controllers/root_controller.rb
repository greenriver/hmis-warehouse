class RootController < ApplicationController
  skip_before_action :authenticate_user!
  def index
  end
end
