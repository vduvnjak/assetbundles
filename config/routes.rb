Rails.application.routes.draw do

  post 'hosting/builds',                   :controller => 'asset_bundle', :action => 'save_build'
  post 'router/:upid/:version',            :controller => 'asset_bundle', :action => 'save_channel'
  get  'router/:upid/:channel_or_version', :controller => 'asset_bundle', :action => 'get_url'
  post 'hosting/querygroup',               :controller => 'asset_bundle', :action => 'get_querygroup'
  post 'hosting/list',                     :controller => 'asset_bundle', :action => 'get_list'

end