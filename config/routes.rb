Rails.application.routes.draw do

  post   'hosting/catalogs',               :controller => 'asset_bundle', :action => 'create_catalog'
  post   'router/:upid/',                  :controller => 'asset_bundle', :action => 'create_channel'
  get    'router/:upid/',                  :controller => 'asset_bundle', :action => 'get_catalog_id'
  post   'hosting/querygroup/:catalog_id', :controller => 'asset_bundle', :action => 'querygroup_assets'
  get    'hosting/list/:catalog_id',       :controller => 'asset_bundle', :action => 'get_asset_list'
  delete 'hosting/:catalog_id/',           :controller => 'asset_bundle', :action => 'delete_catalog'

end