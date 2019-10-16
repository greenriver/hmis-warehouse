###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HelpController < ApplicationController
  include PjaxModalController

  before_action :require_can_edit_help!, except: [ :show ]
  before_action :load_help, except: [ :index, :new , :create]

  def show
    @modal_size = :xl
  end

  def new
    @form_url = help_index_path
    @submit_text = 'Create Help Document'
    @help = if params[:controller_path]
      help_source.where(
        controller_path: params[:controller_path],
        action_name: params[:action_name],
      ).first_or_initialize
    else
      help_source.new
    end
  end

  def create
    @form_url = help_index_path
    @submit_text = 'Create Help Document'
    @help = help_source.create(help_params)
    @help.valid?
    if ! request.xhr?
      respond_with(@help, location: help_index_path)
    end
  end

  def edit
    @form_url = help_path
    @submit_text = 'Save Help Document'
  end

  def index
    @help = help_source.sorted.page(params[:page]).per(25)
  end

  def update
    @form_url = help_path
    @submit_text = 'Save Help Document'
    @help.update(help_params)
    @help.valid?
    if ! request.xhr?
      respond_with(@help, location: help_index_path)
    end
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
      :controller_path,
      :action_name,
      :external_url,
      :title,
      :content,
    )
  end

  def flash_interpolation_options
      { resource_name: 'Help Document' }
    end

end
