class AssetBundleController < ActionController::Base

# POST hosting/builds
# Request:
# {
# 	buildTag: "/orgs/org/projects/myproject/buildtargets/target-1/builds/2",
# 	assetBundles: [
#     	{
#         	name: "Orc",
#         	assetFileHash: "abcdef12345",
#			typeTreeHash: "abcdedf2341",
#           bundleFileHash: "dsfalkds2342",
#           bundleUrl: "http://someurl.com",
#           dependencies: ["abcdef0","abcdef1"]
#     	},
#     	{
#         	name: "Rock",
#         	assetFileHash: "abcdef12345",
#		    typeTreeHash: "abcdedf2341",
#           bundleFileHash: "dsfalkds2342",
#           bundleUrl: "http://someurl.com",
#           dependencies: ["abcdef4","abcdef1"]
#     	}
# 	]
# }

  def save_build
    build_tag     = params["buildTag"]
    asset_bundles = params["assetBundles"]
    asset_names   = asset_bundles.map{|r| r["name"]}

    new_record               = AssetBundle::new
    new_record.build_tag     = build_tag
    new_record.asset_bundles = asset_bundles.to_json
    new_record.asset_names   = asset_names.sort
    build_tag_exists         = AssetBundle.where("build_tag = ? ",build_tag)

    if !build_tag_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
    else
      status = :not_implemented #501
    end

    respond_to do |format|
      format.html { render :nothing => true, :status => status } 
      format.json { render :nothing => true, :status => status } 
    end

  end

# POST /router/:upid/:version
# Request:
# {
#   buildTag: "tagname",
#   channel: "latest" (default: "default")
# }

  def save_channel
    appid     = params["upid"]
    version   = params["version"]
    build_tag = params["buildTag"]
    channel   = params["channel"]

    new_record            = AssetChannel::new
    new_record.version    = version
    new_record.build_tag  = build_tag
    new_record.appid      = appid
    new_record.channel    = channel
    build_tag_exists      = AssetChannel.where("build_tag = ? ",build_tag)

    if !build_tag_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
    else
      status = :not_implemented #501
    end

    respond_to do |format|
      format.html { render :nothing => true, :status => status } 
      format.json { render :nothing => true, :status => status }
    end
  end


# GET /router/:upid/:channel_or_version

# Response:
# 304: /hosting/querygroup/:buildtag

# 410: No longer available
# 404: Not found

  def get_url
  	appid                = params["upid"]
    channel_or_version   = params["channel_or_version"]

    channel_record = AssetChannel.where("appid = ? AND channel = ? ",appid,channel_or_version).last
    version_record = AssetChannel.where("appid = ? AND version = ? ",appid,channel_or_version).last
    
    record = channel_record || version_record

    if record.blank?
      status = :not_found #404
    elsif record && record.deprecated == true
      status = :gone #410
    else # redirect
      status = :found #302
      redirect_to record.build_tag and return
    end

    respond_to do |format|
      format.html { render :nothing => true, :status => status } 
      format.json { render :nothing => true, :status => status }
    end
  end

# POST /hosting/querygroup

# Request:
# {
#   buildTag: “tagname”,
#   have:
#   [
#       {
#           name: "Orc",
#           assetFileHash: "basdlkjfadsfa",
#       	typeTreeHash: “dsfdsfadsf”,
#           bundleFileHash: "dsfalkds2342",
#       }, ...
#   ],
#   need:
#   [
#         "Rock", "Orc"
#   ]
# }

# Response: it is unique array of bundleUrls
# [
#   bundleUrl1, bundleUrl2
# ]

  def get_querygroup
  	build_tag  = params["buildTag"]
    have       = params["have"]
    need       = params["need"] # ["Rock","Orc"]
    haves      = have.map{|r| r["name"]} # ["Orc"]
    not_haves  = need - haves # ["Rock"]

    # find hash subkeys of key "have".
    # Go through asset bundles for given build_tag, and compare all hash keys (assetFileHash,typeTreeHash,bundleFileHash) with ones stored in db
    # build an array of asset objects for assets which do not have same keys, and add dependency objects to it

    asset_bundles_record = AssetBundle.where("build_tag = ? ",build_tag).last
    asset_bundles        = JSON.parse(asset_bundles_record.asset_bundles)
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
		  bundleFileHashKeysMatch = (current_asset.has_key?("bundleFileHash") && db_asset.has_key?("bundleFileHash") && (current_asset['bundleFileHash'] == db_asset['bundleFileHash'])) ? true : false
		  all_keys_match          = assetFileHashKeysMatch && typeTreeHashKeysMatch && bundleFileHashKeysMatch

		  response << create_bundle_url_arry(db_asset,asset_bundles) if !all_keys_match

	 	end

	  end

    end

    if response == []
      status = :not_found
    else
      status = :found
    end

    render :json => response.flatten.uniq
  end

  def create_bundle_url_arry(db_asset,asset_bundles)
  	result =[]
  	result << db_asset if db_asset
	# take care of dependencies by looking at db_asset
	# [{"name"=>"Orc", "assetFileHash"=>"abcdef12345", "typeTreeHash"=>"dsfadsfa", "bundleFileHash"=>"dsfalkds2342", "dependencies"=>["Ball"]}]
	dependencies = db_asset["dependencies"]
	dependencies.each do |dep|
	  # for this particular dependency, look inside of this build and get bundleUrl
	  dep_db_asset = asset_bundles.select {|ab| ab["name"] == dep }.first
	  result << dep_db_asset if dep_db_asset
	end
	result
  end

# POST /hosting/list/

# Request: {}
# {buildTag: “tagname”}

# Response:
# [
#   "Rock","Orc"
# ]

  def get_list
  	build_tag            = params["buildTag"]
  	asset_bundles_record = AssetBundle.where("build_tag = ? ",build_tag).last
    asset_bundles        = JSON.parse(asset_bundles_record.asset_bundles)
    asset_names          = asset_bundles.map{|r| r["name"]}

  	render :json => asset_names.uniq
  end

end