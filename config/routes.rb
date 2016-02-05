Rails.application.routes.draw do

  namespace :api, defaults: { format: :json } do
    post   'hosting/catalogs',                   :controller => 'asset_bundle', :action => 'create_catalog'
    post   'router/:upid/',                      :controller => 'asset_bundle', :action => 'create_channel'
    get    'router/:upid/',                      :controller => 'asset_bundle', :action => 'get_catalog_id'
    post   'hosting/catalogs/:catalog_id/query', :controller => 'asset_bundle', :action => 'querygroup_assets'
    get    'hosting/catalogs/:catalog_id/list',  :controller => 'asset_bundle', :action => 'get_asset_list'
    delete 'hosting/:catalog_id/',               :controller => 'asset_bundle', :action => 'delete_catalog'
    get    'hosting/catalogs',                   :controller => 'asset_bundle', :action => 'get_catalog_list'
  end

end