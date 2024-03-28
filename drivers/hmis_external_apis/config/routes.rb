BostonHmis::Application.routes.draw do
  scope(module: :hmis_external_apis) do
    scope(module: :ac_hmis) do
      post '/hmis_external_api/ac_hmis/referrals',
           to: 'referrals#create',
           as: 'hmis_external_apis_referrals',
           defaults: { format: 'json' }

      get '/hmis_external_api/ac_hmis/program_involvements',
          to: 'involvements#program',
          as: 'hmis_external_apis_program_involvements',
          defaults: { format: 'json' }

      get '/hmis_external_api/ac_hmis/client_involvements',
          to: 'involvements#client',
          as: 'hmis_external_apis_client_involvements',
          defaults: { format: 'json' }
    end
    if Rails.env.development?
      # testing only
      get '/hmis_external_api/external_forms/presign', as: 'presign_hmis_external_apis_external_form', to: 'external_forms#presign'
      get '/hmis_external_api/external_forms/*object_key', as: 'hmis_external_apis_external_form', to: 'external_forms#show', defaults: { format: 'html' }
      put '/hmis_external_api/external_forms', as: 'create_hmis_external_apis_external_form', to: 'external_forms#create'
    end
  end
end
