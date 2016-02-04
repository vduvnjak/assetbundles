class Api::AssetBundleController < ActionController::Base

# POST /api/hosting/catalogs
# Request:
# {
# 	catalogId: "catalogIdhash",
# 	assetBundles: [
#     	{
#         	name: "Orc",
#         	assetFileHash: "abcdef12345",
#			      typeTreeHash: "abcdedf2341",
#           bundleFileHash: "dsfalkds2342",
#           bundleUrl: "http://someurl.com",
#           dependencies: ["abcdef0","abcdef1"]
#     	},
#     	{
#         	name: "Rock",
#         	assetFileHash: "abcdef12345",
#		        typeTreeHash: "abcdedf2341",
#           bundleFileHash: "dsfalkds2342",
#           bundleUrl: "http://someurl.com",
#           dependencies: ["abcdef4","abcdef1"]
#     	}
# 	]
# }
# Response {"status":status}

  def create_catalog
    catalog_id    = params["catalogId"]
    asset_bundles = params["assetBundles"]

    new_record               = AssetBundle::new
    new_record.catalog_id    = catalog_id
    new_record.asset_bundles = asset_bundles.to_json
    catalog_id_exists        = AssetBundle.where("catalog_id = ? ",catalog_id)

    if !catalog_id_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
    else
      status = :not_implemented #501
    end

    render :json => {}.to_json, :status => status
  end

# POST /api/router/:upid
# Request:
# {
#   catalogId: "catalogIdhash",
#   channel: "latest" 
# }
# Response {"status":status}

  def create_channel
    upid       = params["upid"]
    catalog_id = params["catalogId"]
    channel    = params["channel"]

    new_record            = AssetChannel::new
    new_record.catalog_id = catalog_id
    new_record.upid       = upid
    new_record.channel    = channel
    record_exists         = AssetChannel.where("catalog_id=? AND upid=? AND channel=?",catalog_id,upid,channel)

    if !record_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
    else
      status = :not_implemented #501
    end

    render :json => {}.to_json, :status => status
  end

# GET api/router/:upid?channel=greatest
# Response: {"catalogId":"catalogIdhash2", "status":status}

  def get_catalog_id
  	upid      = params["upid"]
    channel   = params["channel"]
    record    = AssetChannel.where("upid = ? AND channel = ? ",upid,channel).last

    if record.blank?
      catalog_id = ""
      status = :not_found #404
    else
      catalog_id = record.catalog_id
      status = :found #302
    end

    render :json => {"catalogId"=>catalog_id}.to_json, :status => status 
  end

# POST /hosting/querygroup/:catalog_id

# Request:
# {
#   have:
#   [
#       {
#           name: "Orc",
#           assetFileHash: "basdlkjfadsfa",
#       	  typeTreeHash: “dsfdsfadsf”,
#           bundleFileHash: "dsfalkds2342",
#       }, ...
#   ],
#   need:
#   [
#         "Rock", "Orc"
#   ]
# }
# Response: it is unique array of asset bundle objects
# {"bundles":[bundle1,bundle2], "status" : status }

  def querygroup_assets
  	catalog_id = params["catalog_id"]
    have       = params["have"]
    need       = params["need"] # ["Rock","Orc"]
    haves      = have.map{|r| r["name"]} # ["Orc"]
    not_haves  = need - haves # ["Rock"]

    # find hash subkeys of key "have".
    # Go through asset bundles for given catalog_id, and compare some hash keys (assetFileHash,typeTreeHash) with ones stored in db
    # build an array of asset objects for unmatching keys, and add dependency objects to it

    asset_bundles_record = AssetBundle.where("catalog_id = ? ",catalog_id).last
    asset_bundles        = asset_bundles_record ? JSON.parse(asset_bundles_record.asset_bundles) : []
    response = []

    need.each do |asset_name|
      db_asset = asset_bundles.select {|ab| ab["name"] == asset_name }.first

      if db_asset

  	    if not_haves.include?(asset_name) # we dont have this asset at all get one from db asset_bundle
  	      response << create_bundle_url_arry(db_asset,asset_bundles)
    	 	else # we have asset, but must check the hashes in order to add bundle urls
    	    
    		  current_asset           = have.select {|ab| ab["name"] == asset_name }.first
    		  assetFileHashKeysMatch  = (current_asset.has_key?("assetFileHash") && db_asset.has_key?("assetFileHash") && (current_asset['assetFileHash'] == db_asset['assetFileHash'])) ? true : false
    		  typeTreeHashKeysMatch   = (current_asset.has_key?("typeTreeHash") && db_asset.has_key?("typeTreeHash") && (current_asset['typeTreeHash'] == db_asset['typeTreeHash'])) ? true : false
    		  all_keys_match          = current_asset.has_key?("typeTreeHash") ? assetFileHashKeysMatch && typeTreeHashKeysMatch : assetFileHashKeysMatch

    		  response << create_bundle_url_arry(db_asset,asset_bundles) if !all_keys_match

    	 	end

  	  end

    end

    if response == []
      status = :not_found
    else
      status = :found
    end

    render :json => {"bundles"=>response.flatten.uniq}.to_json, :status => status 
  end

  def create_bundle_url_arry(db_asset,asset_bundles)
  	result =[]
  	result << db_asset if db_asset
  	# take care of dependencies by looking at db_asset
  	# [{"name"=>"Orc", "assetFileHash"=>"abcdef12345", "typeTreeHash"=>"dsfadsfa", "bundleFileHash"=>"dsfalkds2342", "dependencies"=>["Ball"]}]
  	dependencies = db_asset["dependencies"]
  	dependencies.each do |dep|
  	  # for this particular dependency, look inside of this build and get asset
  	  dep_db_asset = asset_bundles.select {|ab| ab["name"] == dep }.first
  	  result << dep_db_asset if dep_db_asset
  	end
	  result
  end

# POST /api/hosting/list/:catalog_id
# Response:
# {"assetNames":["Rock","Orc"], "status" : status }


  def get_asset_list
  	catalog_id           = params["catalog_id"]
  	asset_bundles_record = AssetBundle.where("catalog_id = ? ",catalog_id).last
    if asset_bundles_record
      asset_bundles      = JSON.parse(asset_bundles_record.asset_bundles)
      asset_names        = asset_bundles.map{|r| r["name"]}
    else
      asset_bundles = []
      asset_names = []
    end

    if asset_bundles.blank?
      status = :not_found
    else
      status = :found
    end

    render :json => {"assetNames"=>asset_names.uniq}.to_json, :status => status
  end

# DELETE /hosting/:catalog_id
# Response:{{}, "status" : status }

  def delete_catalog
    catalog_id = params["catalog_id"]
	  asset_bundles_record = AssetBundle.where("catalog_id = ? ",catalog_id).last
	

    if asset_bundles_record && asset_bundles_record.destroy
      status = :ok
    else 
      status = :not_ok
    end

    render :json => {}.to_json, :status => status
  end

# GET /api/hosting/list
# Response:{{list of catalogues}, "status" : status }

def get_catalog_list
  catalogs  = AssetBundle.all
  cat_array = []
  catalogs.each do |c|
    cat_array<< {"catalogId"=>c.catalog_id, "assetBundles"=>c.asset_bundles}
  end

  status = :ok

  render :json => cat_array.to_json, :status => status
end

end