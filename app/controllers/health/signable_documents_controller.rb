###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class SignableDocumentsController < IndividualPatientController
    include ClientPathGenerator
    include HealthCareplan

    helper ChaHelper

    before_action :set_client, except: [:signature, :signed]
    before_action :set_hpc_patient, except: [:signature, :signed]
    before_action :set_careplan, except: [:signature, :signed]
    before_action :set_medications, except: [:signature, :signed]
    before_action :set_problems, except: [:signature, :signed]

    # This supports signing without logging in:
    skip_before_action :authenticate_user!, only: [:signature, :signed]
    skip_before_action :require_some_patient_access!, only: [:signature, :signed]

    def create
      @team = @careplan.team

      @signers = []
      @signers << { 'email': @patient.current_email, 'name': @patient.name }

      @doc = @careplan.signable_documents.build(signers: @signers, primary: true, user_id: current_user.id)

      @doc.pdf_content_to_upload = generate_pdf

      if @doc.valid?
        @careplan.class.transaction do
          @doc.save
          @careplan.signable_documents.where.not(id: @doc.id).update_all(primary: false)
          @expires_at = Time.now + signature_source.expires_in
          @signature_request = signature_source.create!(
            patient_id: @patient.id,
            careplan_id: @careplan.id,
            to_email: @patient.current_email,
            to_name: "#{@patient.first_name} #{@patient.last_name}",
            requestor_email: current_user.email,
            requestor_name: current_user.name,
            sent_at: Time.now,
            expires_at: @expires_at,
            signable_document_id: @doc.id,
          )
          @doc.make_document_signable!
        end

        flash[:notice] = "Careplan signature requested from #{@doc.signers.map(&:email).join('; ')}"
      else
        flash[:error] = @doc.errors.full_messages.join('. ').to_s
      end
      url_params = { client_id: @client.id, careplan_id: @careplan.id, id: @doc.id, email: @patient.current_email, hash: @doc.signer_hash(@patient.current_email) }
      url_params[:sign_out] = true if params[:sign_out].present?
      redirect_to polymorphic_path([:signature] + careplan_path_generator + [:signable_document], url_params)
      # redirect_back fallback_location: client_health_careplans_path(@client)
    end

    # def remind
    #   @careplan = @patient.careplans.find(params[:careplan_id])
    #   @doc      = @careplan.primary_signable_document

    #   @doc.remind!(email)

    #   flash.notice = "Reminded #{email}"
    #   redirect_back fallback_location: client_health_careplans_path(@client)
    # end

    def signature
      @state = :valid
      @doc = Health::SignableDocument.find(params[:id])
      @doc.update(expires_at: Health::SignableDocument.patient_expiration_window) if current_user.present?
      sign_out(:user) if params[:sign_out].present?

      if @doc.signer_hash(params[:email]) == params[:hash] && ! @doc.expired? && ! @doc.signed?
        if @doc.signature_request&.pcp_request?
          params[:post_sign_path] = polymorphic_path([:signed] + careplan_path_generator + [:signable_document],
                                                     client_id: params[:client_id],
                                                     careplan_id: params[:careplan_id],
                                                     id: @doc.id,
                                                     hash: params[:hash],
                                                     email: params[:email])
        end
        @signature_request_url = @doc.signature_request_url(params[:email])
      elsif @doc.signed?
        @state = :signed
      elsif @doc.expired?
        @doc = nil
        @state = :expired
      else
        not_authorized!
        nil
      end
    rescue HelloSign::Error, HelloSign::Error::Conflict
      render 'error'
    end

    def signed
      @doc = Health::SignableDocument.find(params[:id])
      if @doc.signer_hash(params[:email]) == params[:hash] && ! @doc.expired?
        if @doc.signature_request
          signed_at = Time.now
          @doc.signature_request.update(completed_at: signed_at)
          careplan = @doc.signature_request.careplan
          if @doc.signature_request.pcp_request?
            # make sure the PCP listed on the careplan is the same one we collected the signature from
            careplan.assign_attributes(
              provider_id: @doc.team_member.id,
              provider_signed_on: signed_at,
            )
          end
          # This gets called by a non-user, log this as a system user
          Health::CareplanSaver.new(careplan: careplan, user: User.setup_system_user, create_qa: true).update
        end
      end

      flash[:notice] = 'Thank you. Your Care Plan signature was submitted.'
    end

    private

    def signature_source
      Health::SignatureRequests::PatientSignatureRequest
    end

    def generate_pdf
      pdf = careplan_combine_pdf_object
      @pdf = pdf.to_pdf
    end
  end
end
