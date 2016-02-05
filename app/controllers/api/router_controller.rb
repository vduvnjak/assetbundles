class Api::RouterController < ActionController::Base

  resource_description do
    name "Router"
    short "Maps client configuration to hosting catalogs"
    desc ""
  end

# POST /api/router/:upid
# Request:
# {
#   catalogId: "catalogIdhash",
#   channel: "latest"
# }
# Response: {"id":id}, "status":status

  api! 'Create a new routing rule'
  def create_channel
    upid       = params["upid"]
    catalog_id = params["catalogId"]
    channel    = params["channel"]

    new_record            = AssetChannel::new
    new_record.catalog_id = catalog_id
    new_record.upid       = upid
    new_record.channel    = channel
    record_exists         = AssetChannel.where("catalog_id=? AND upid=? AND channel=?",catalog_id,upid,channel)

    data = {}
    if !record_exists.blank?
      status = :no_content #204
    elsif new_record.save
      status = :created #201
      data = {"id"=>new_record.id}
    else
      status = :not_implemented #501
    end

    render :json => data.to_json, :status => status
  end

# GET api/router/:upid?channel=greatest
# Response: {"catalogId":"catalogIdhash2"}, "status":status

  api! 'Lookup a catalog'
  param :channel, String, 'Query for a specific channel'
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
end