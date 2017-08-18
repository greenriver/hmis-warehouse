module Window::Clients
  class VispdatsController < ApplicationController
    include WindowClientPathGenerator

    before_action :require_can_view_vspdat!, only: [:index, :show]
    before_action :require_can_edit_vspdat!, only: [:new, :create, :edit, :update, :destroy]

    before_action :set_client
    before_action :set_vispdat, only: [:show, :edit, :update, :destroy]

    def index
      @vispdats = @client.vispdats.order(created_at: :desc)
      respond_with(@vispdats)
    end

    def show
      respond_with(@vispdat)
    end

    # def new
    #   @vispdat = @client.vispdats.build
    #   @vispdat.save(validate: false)
    #   respond_with(@vispdat, action: :edit)
    # end

    def edit
    end

    def create
      if @client.vispdats.in_progress.none?
        @vispdat = @client.vispdats.build
        @vispdat.save(validate: false)
      else
        @vispdat = @client.vispdats.in_progress.first
      end
      respond_with(@vispdat, location: polymorphic_path([:edit] + vispdat_path_generator, client_id: @client.id, id: @vispdat.id))
    end

    def update
      if params[:commit]=='Complete'
        @vispdat.update(vispdat_params.merge(submitted_at: Time.now))
      else
        @vispdat.assign_attributes(vispdat_params)
        @vispdat.save(validate: false)
      end
      respond_with(@vispdat, location: polymorphic_path(vispdats_path_generator, client_id: @client.id))
    end

    private

      def set_client
        @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id])
      end

      def set_vispdat
        @vispdat = GrdaWarehouse::Vispdat.find(params[:id])
      end

      def vispdat_params
        params.require(:grda_warehouse_vispdat).permit(:nickname, :language_answer, :release_signed_on, :hiv_release, :drug_release, :sleep_answer, :sleep_answer_other, :homeless, :homeless_refused, :homeless_period, :episodes_homeless, :episodes_homeless_refused, :emergency_healthcare, :emergency_healthcare_refused, :ambulance, :ambulance_refused, :inpatient, :inpatient_refused, :crisis_service, :crisis_service_refused, :talked_to_police, :talked_to_police_refused, :jail, :jail_refused, :attacked_answer, :threatened_answer, :legal_answer, :tricked_answer, :risky_answer, :owe_money_answer, :get_money_answer, :activities_answer, :basic_needs_answer, :abusive_answer, :leave_answer, :chronic_answer, :hiv_answer, :disability_answer, :avoid_help_answer, :pregnant_answer, :eviction_answer, :drinking_answer, :mental_answer, :head_answer, :learning_answer, :brain_answer, :medication_answer, :sell_answer, :trauma_answer, :find_location, :find_time, :when_answer, :phone, :email, :picture_answer)
      end
  end
end
