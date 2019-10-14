###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HelpController < ApplicationController
  include PjaxModalController
  before_action :load_help, except: [ :index, :new , :create]

  def show
    @modal_size = :xl
  end

  def new
    @help = if params[:path]
      help_source.where(path: params[:path]).first_or_initialize
    else
      help_source.new
    end
  end

  def create
    @help = help_source.create(help_params)
    respond_with(@help, location: help_index_path)
  end

  def edit

  end

  def index
    @help = help_source.sorted.page(params[:page]).per(25)
  end

  def update
    @help.update(help_params)
    respond_with(@help, location: help_index_path)
  end

  def destroy
    @help.destroy
    respond_with(@help, location: help_index_path)
  end

  private def load_help
    @help = help_source.find(params[:id].to_i)
  end

  private def help_source
    GrdaWarehouse::Help
  end

  private def help_params
    param_key = help_source.model_name.param_key
    params.require( param_key ).permit(
      :path,
      :title,
      :content,
    )
  end

  def flash_interpolation_options
      { resource_name: 'Help Document' }
    end

end
