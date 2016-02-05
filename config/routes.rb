Rails.application.routes.draw do

  apipie
  namespace :api, defaults: { format: :json } do
    post   'router/:upid/',                      :controller => 'router',  :action => 'create_channel'
    get    'router/:upid/',                      :controller => 'router',  :action => 'get_catalog_id'
    put    'router/:upid/',                      :controller => 'router',  :action => 'update_channel'
    get    'hosting/catalogs',                   :controller => 'hosting', :action => 'get_catalog_list'
    post   'hosting/catalogs',                   :controller => 'hosting', :action => 'create_catalog'
    post   'hosting/catalogs/:catalog_id/query', :controller => 'hosting', :action => 'querygroup_assets'
    get    'hosting/catalogs/:catalog_id/list',  :controller => 'hosting', :action => 'get_asset_list'
    delete 'hosting/catalogs/:catalog_id/',      :controller => 'hosting', :action => 'delete_catalog'
  end

end