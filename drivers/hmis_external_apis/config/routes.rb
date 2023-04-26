BostonHmis::Application.routes.draw do
  scope(module: :hmis_external_apis) do
    post('/hmis_external_api/ac_hmis/referrals', to: 'referrals#create', as: 'hmis_external_apis_referrals', defaults: { format: 'json' })
  end
end
