class Api::HostingController < ActionController::Base

  resource_description do
    name "Hosting"
    short "Provides content catalog information to clients"
    desc ""
  end

  api! 'Create a new asset bundle catalog'
  example 'POST /api/hosting/catalogs
{
    "catalogId": "catalogIdhash2",
    "assetBundles": [
        {
            "name": "Orc",
            "assetFileHash": "assetFileHashForOrc",
            "typeTreeHash": "typeTreeHashForOrc",
            "bundleFileHash": "bundleFileHashForOrc",
            "bundleUrl": "bundleUrlForOrc",
            "dependencies": [
                "Ball"
            ]
        },
        {
            "name": "Rock",
            "assetFileHash": "assetFileHashForRock",
            "typeTreeHash": "typeTreeHashForRock",
            "bundleFileHash": "bundleFileHashForRock",
            "bundleUrl": "bundleUrlForRock",
            "dependencies": [
                "Orc"
            ]
        }
    ]
}

Response:
{
    "catalog_id": "catalogid"
}'
  param :catalogId, String, :desc => "Catalog ID", :required => true
  param :assetBundles, Array, :desc => "List of asset bundles" do
    param :name, String
    param :assetFileHash, String
    param :typeTreeHash, String
    param :bundleFileHash, String
    param :bundleUrl, String
    param :dependencies, Array, of: String
  end
  def create_catalog
    catalog_id    = params["catalogId"]
    asset_bundles = params["assetBundles"]

    new_record               = AssetBundle::new
    new_record.catalog_id    = catalog_id
    new_record.asset_bundles = get_asset_ids(asset_bundles) # return an array of asset ids
    catalog_id_exists        = AssetBundle.where("catalog_id = ? ",catalog_id)

    data = {}
    if !catalog_id_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
      data   = {"catalog_id"=>new_record.catalog_id}
    else
      status = :not_implemented #501
    end

    render :json => data.to_json, :status => status
  end

  def get_asset_ids(asset_bundles)
    # check if asset already exist with exact same name, hashes and bundleUrl. If yes, use that id. If not, create new one.
    assets=[]
    asset_bundles.each do |ab|
      db_asset = Asset.where("name=? AND assetFileHash=? AND typeTreeHash=? AND bundleFileHash=? AND bundleUrl=?",ab["name"],ab["assetFileHash"],ab["typeTreeHash"],ab["bundleFileHash"],ab["bundleUrl"]).last
      if db_asset.blank?
        new_asset = Asset.new
        new_asset.name = ab["name"]
        new_asset.assetFileHash = ab["assetFileHash"]
        new_asset.typeTreeHash = ab["typeTreeHash"]
        new_asset.bundleFileHash = ab["bundleFileHash"]
        new_asset.bundleUrl = ab["bundleUrl"]
        new_asset.dependencies = ab["dependencies"].blank? ? [] : ab["dependencies"].sort
        assets<<new_asset.id if new_asset.save
      else
        assets<<db_asset.id
      end
    end
    assets
  end

  api! 'Query a catalog'
  example 'POST api/hosting/catalogs/ababad235a8cfs2454/query
{
    "have": [
        {
            "name": "Orc",
            "assetFileHash": "basdlkjfadsfa",
            "typeTreeHash": "dsfdsfadsf",
            "bundleFileHash": "dsfalkds2342"
        }
    ],
    "need": [
        "Rock",
        "Orc"
    ]
}

Response:
{
    "bundles": [
        {
            "name": "Orc",
            "assetFileHash": "assetFileHashForOrc",
            "typeTreeHash": "typeTreeHashForOrc",
            "bundleFileHash": "bundleFileHashForOrc",
            "bundleUrl": "bundleUrlForOrc"
        },
        {
            "name": "Rock",
            "assetFileHash": "assetFileHashForRock",
            "typeTreeHash": "typeTreeHashForRock",
            "bundleFileHash": "bundleFileHashForRock",
            "bundleUrl": "bundleUrlForRock"
        }
    ]
}'
    param :have, Array, :desc => "Asset bundles the client already has" do
      param :name, String
      param :assetFileHash, String
    end
    param :need, Array, of: String, :desc => "Names of requested asset bundles"
  def querygroup_assets
  	catalog_id = params["catalog_id"]
    have       = params["have"]
    need       = params["need"] # ["Rock","Orc"]
    haves      = have.blank? ? [] : have.map{|r| r["name"]} # ["Orc"]
    not_haves  = need - haves # ["Rock"]

    # find hash subkeys of key "have".
    # Go through asset bundles for given catalog_id, and compare some hash keys (assetFileHash,typeTreeHash) with ones stored in db
    # build an array of asset objects for unmatching keys, and add dependency objects to it

    asset_bundles_record = AssetBundle.where("catalog_id = ? ",catalog_id).last
    if asset_bundles_record
      asset_ids     = asset_bundles_record.asset_bundles
      asset_bundles = asset_ids ? Asset.where("id IN (?)",asset_ids).to_a : []
      #[#<Asset id: 12, name: "Orc", assetFileHash: "assetFileHashForOrc", typeTreeHash: "typeTreeHashForOrc", bundleFileHash: "bundleFileHashForOrc", bundleUrl: "bundleUrlForOrc", dependencies: "[\"Ball\", \"Rock\"]">, #<Asset id: 13, name: "Rock", assetFileHash: "assetFileHashForRock", typeTreeHash: "typeTreeHashForRock", bundleFileHash: "bundleFileHashForRock", bundleUrl: "bundleUrlForRock", dependencies: "[\"Orc\"]">]
    else
      asset_bundles = []
    end

    response = []

    need.each do |asset_name|
      db_asset = asset_bundles.select {|ab| ab.name == asset_name }.first
      #<Asset id: 12, name: "Orc", assetFileHash: "assetFileHashForOrc", typeTreeHash: "typeTreeHashForOrc", bundleFileHash: "bundleFileHashForOrc", bundleUrl: "bundleUrlForOrc", dependencies: "[\"Ball\", \"Rock\"]">

      if db_asset

  	    if not_haves.include?(asset_name) # we dont have this asset at all get one from db asset_bundle
  	      response << create_bundle_asset_arry(db_asset,asset_bundles)
    	 	else # we have asset, but must check the hashes in order to add bundle urls
    	    
    		  current_asset           = have.select {|ab| ab["name"] == asset_name }.first
    		  assetFileHashKeysMatch  = current_asset['assetFileHash'] == db_asset['assetFileHash'] ? true : false
    		  typeTreeHashKeysMatch   = current_asset['typeTreeHash'] == db_asset['typeTreeHash'] ? true : false
    		  all_keys_match          = current_asset['typeTreeHash'].blank? ? assetFileHashKeysMatch : assetFileHashKeysMatch && typeTreeHashKeysMatch

    		  response << create_bundle_asset_arry(db_asset,asset_bundles) if !all_keys_match

    	 	end

  	  end

    end

    if response == []
      status = :not_found
    else
      status = :found
    end

    render :json => {"bundles"=>response.flatten.uniq}, :status => status 
  end

  def create_bundle_asset_arry(db_asset,asset_bundles)
  	result =[]
  	result << db_asset if db_asset
  	# take care of dependencies by looking at db_asset
  	# [{"name"=>"Orc", "assetFileHash"=>"abcdef12345", "typeTreeHash"=>"dsfadsfa", "bundleFileHash"=>"dsfalkds2342", "dependencies"=>["Ball"]}]
  	dependencies = db_asset["dependencies"]
  	dependencies.each do |dep|
  	  # for this particular dependency, look inside of this build and get asset
  	  dep_db_asset = asset_bundles.select {|ab| ab.name == dep }.first
  	  result << dep_db_asset if dep_db_asset
  	end
	  result
  end

  api! 'List all assets in a catalog'
  example 'GET /api/hosting/catalogs/ababad235a8cfs2454/list

Response:
{
    "assetNames": [
        "Rock",
        "Orc"
    ]
}'
  def get_asset_list
  	catalog_id           = params["catalog_id"]
  	asset_bundles_record = AssetBundle.where("catalog_id = ? ",catalog_id).last
    if asset_bundles_record
      asset_ids     = asset_bundles_record.asset_bundles
      asset_bundles = asset_ids ? Asset.where("id IN (?)",asset_ids).to_a : []
      asset_names   = asset_bundles.map{|r| r["name"]}
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

  api! 'Delete a catalog'
  example 'DELETE api/hosting/catalogs/:catalog_id

Response:
{}'
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

  api! 'List all available catalogs and their contents'
  example 'GET /api/hosting/catalogs

Response:
[
    {
        "catalogId": "7c8cd1ff6e8b1a3a3ebbbd4668b030b401496825",
        "assetBundles": []
    },
    {
        "catalogId": "9c0f6badebf3c830197967b85cd9720bc78f5dc6",
        "assetBundles": [
            {
                "id": 1,
                "name": "scene-bundle",
                "assetFileHash": "9766e2500d38bde091486f9c58634f02",
                "typeTreeHash": "1d923ba6d826e40d3b66133490c95925",
                "bundleFileHash": "4d04f2104d8318baf7378d1fdd6ee3b7671bb8fe",
                "bundleUrl": "https://s3.amazonaws.com/bucket/0895632b-43a2-4fd3-85f0-852d8fb807ba/4d04f2104d8318baf7378d1fdd6ee3b7671bb8fe",
                "dependencies": [
                    "material-bundle"
                ]
            },
            {
                "id": 2,
                "name": "variants/myassets.hd",
                "assetFileHash": "44f3bc1bdd0baa954730008d57ef99a7",
                "typeTreeHash": "a7fe22443e13028af8d92cdcec24d183",
                "bundleFileHash": "b0a960ca9d06f59e737b2bffed726a93b7e22b7e",
                "bundleUrl": "https://s3.amazonaws.com/bucket/0895632b-43a2-4fd3-85f0-852d8fb807ba/b0a960ca9d06f59e737b2bffed726a93b7e22b7e",
                "dependencies": []
            }
        ]
    }
]'
  def get_catalog_list
    catalogs  = AssetBundle.all
    cat_array = []
    catalogs.each do |c|
      asset_ids     = c.asset_bundles
      asset_bundles = asset_ids ? Asset.where("id IN (?)",asset_ids).to_a : []
      cat_array<< {"catalogId"=>c.catalog_id, "assetBundles"=>asset_bundles}
    end

    status = :ok

    render :json => cat_array.to_json, :status => status
  end

end