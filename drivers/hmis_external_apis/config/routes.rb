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
      post '/hmis_external_api/static_pages/presign', as: 'presign_hmis_external_apis_static_page', to: 'static_pages#presign'
      get '/hmis_external_api/static_pages/*template', as: 'hmis_external_apis_static_page', to: 'static_pages#show', defaults: { format: 'html' }
      put '/hmis_external_api/static_pages', as: 'create_hmis_external_apis_static_page', to: 'static_pages#create'
    end
  end
end
