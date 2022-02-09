###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class VispdatsController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_access_vspdat_list!, only: [:index, :show]
    before_action :require_can_create_or_modify_vspdat!, except: [:index, :show]
    before_action :set_client
    before_action :set_vispdat, except: [:new, :create, :index]
    before_action :require_can_edit_vspdat!, only: [:destroy]
    after_action :log_client

    def index
      @vispdats = @client.vispdats.
        order(created_at: :desc)
      respond_with(@vispdats)
    end

    def show
      if @vispdat.visible_by?(current_user)
        respond_with(@vispdat)
      else
        not_authorized!
      end
    end

    def edit
      if @vispdat.show_as_readonly?
        render(:show)
        return
      end
      @consent_form_url = GrdaWarehouse::PublicFile.url_for_location 'client/hmis_consent'
      @file = GrdaWarehouse::ClientFile.new(vispdat_id: @vispdat.id)
    end

    def destroy
      @vispdat.disassociate_files
      @vispdat.destroy
      respond_with(@vispdat, location: client_vispdats_path(@client))
    end

    # VI-SPDAT can be of types: individual, youth or family, determined by params[:type]
    def create
      if @client.vispdats.in_progress.none?
        @vispdat = build_vispdat
        @vispdat.save(validate: false)
      else
        @vispdat = @client.vispdats.in_progress.first
      end
      respond_with(@vispdat, location: polymorphic_path([:edit] + vispdat_path_generator, client_id: @client.id, id: @vispdat.id))
    end

    def update
      # We're marking this VI-SPDAT as complete
      if params[:commit] == 'Complete'
        # set this one as active
        @vispdat.update(vispdat_params.merge(submitted_at: Time.now, active: true, user_id: current_user.id))
        # mark any other actives as inactive
        @client.vispdats.where(active: true).where.not(id: @vispdat.id).update_all(active: false)
      # Post completion we are marking the housing release as confirmed
      elsif @vispdat.submitted_at.present?
        @vispdat.update_attribute(:housing_release_confirmed, params[:housing_release_confirmed].present?)
        @vispdat.set_client_housing_release_status
        @vispdat.update_column(:housing_release_confirmed, params[:housing_release_confirmed].present?)

      # We're updating an incomplete VI-SPDAT
      else
        @vispdat.assign_attributes(vispdat_params.merge(user_id: current_user.id))
        @vispdat.save(validate: false)
      end
      @file = GrdaWarehouse::ClientFile.new(vispdat_id: @vispdat.id)
      respond_with(@vispdat, location: polymorphic_path(vispdats_path_generator, client_id: @client.id))
    end

    def add_child
      @child = @vispdat.children.create(first_name: 'First', last_name: 'Last') if @vispdat.family?
      redirect_to polymorphic_path([:edit] + vispdat_path_generator, client_id: @client.id, id: @vispdat.id, anchor: 'children-fields')
    end

    def remove_child
      return unless @vispdat.family?

      @child = @vispdat.children.where(id: params[:child_id]).first
      @child&.destroy
    end

    def upload_file
      set_vispdat
      @file = GrdaWarehouse::ClientFile.new
      # begin
      file = file_params[:file]
      @file.assign_attributes(
        file: file,
        client_id: @client.id,
        user_id: current_user.id,
        content_type: file&.content_type,
        content: file&.read,
        visible_in_window: true,
        note: file_params[:note],
        name: file.original_filename,
        vispdat_id: @vispdat.id,
        consent_form_signed_on: file_params[:effective_date],
        effective_date: file_params[:effective_date],
      )
      consent_form = 'Consent Form'
      # @file.tag_list.add(tag_list.select(&:present?))
      # force consent form for now
      @file.tag_list.add [consent_form]
      @file.save!

      flash[:notice] = "File #{file_params[:name]} saved."
      # rescue Exception => e
      #   flash[:error] = e.message
      # end
      redirect_to action: :edit
    end

    def destroy_file
      set_vispdat
      @file = @vispdat.files.find params[:file_id]
      @file.destroy
      respond_with @vispdat
    end

    private def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    private def set_vispdat
      @vispdat = vispdat_source.find(params[:id].to_i)
    end

    private def vispdat_source
      GrdaWarehouse::Vispdat::Base
    end

    private def build_vispdat
      vispdat_type = GrdaWarehouse::Vispdat::Base.available_types.detect { |m| m == params[:type] } || 'GrdaWarehouse::Vispdat::Individual'
      @client.vispdats.build(user_id: current_user.id, type: vispdat_type)
    end

    private def vispdat_params
      # this will be one of:
      # grda_warehouse_vispdat_individual
      # grda_warehouse_vispdat_youth
      # grda_warehouse_vispdat_family
      param_key = @vispdat.class.model_name.param_key
      params.require(param_key).permit(*@vispdat.class.allowed_parameters)
    end

    private def file_params
      params.require(:grda_warehouse_client_file).
        permit(
          :file,
          :name,
          :note,
          :visible_in_window,
          :effective_date,
          tag_list: [],
        )
    end

    private def tag_list
      file_params[:tag_list] || []
    end

    private def title_for_show
      "#{@client.name} - VI-SPDATs"
    end
  end
end
