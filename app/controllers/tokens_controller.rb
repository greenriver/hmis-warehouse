###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TokensController < ApplicationController
  before_action :set_token

  def show
    if @token.present?
      redirect_to @token.path
    else
      flash[:alert] = Translation.translate('Unable to find link')
      redirect_to root_path
    end
  end

  def set_token
    @token = token_scope.find_by(token: params[:id])
  end

  def token_scope
    Token.valid
  end
end
