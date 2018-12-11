
class TokensController < ApplicationController
  before_action :set_token

  def show
    if @token.present?
      redirect_to @token.path
    else
      flash[:alert] = _("Unable to find link")
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
