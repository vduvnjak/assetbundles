class Api::RouterController < ActionController::Base

  resource_description do
    name "Router"
    short "Maps client configuration to hosting catalogs"
    desc ""
  end

  api! 'Create a new routing rule'
  example 'POST /api/router/12345-abcde-13434-abcde
{
    "catalogId": "catalog",
    "channel": "latest"
}

Response:
{
    "id": "id"
}'
  param :query, Hash, :desc => "Router query parameters" do
    param :catalogId, String, :required => true
    param :channel, String
  end
  def create_channel
    upid       = params["upid"]
    catalog_id = params["catalogId"]
    channel    = params.has_key?("channel") ? params["channel"] : nil

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


  api! 'Update asset channel'
  example 'PUT api/router/12345-abcde-13434-abcde
{
  "catalogId": "catalog",
  "channel": "latest"
}

Response:
{
    "id": "id"
}'
  param :query, Hash, :desc => "Router query parameters" do
    param :catalogId, String, :required => true
    param :channel, String, 'Query for a specific channel to update'
  end

  def update_channel
    upid       = params["upid"]
    catalog_id = params["catalogId"]
    channel    = params["channel"]
    record     = AssetChannel.where("upid = ? AND catalog_id = ? ",upid,catalog_id).last

    if record.blank?
      status = :not_found #404
    else
      attributes = {:channel => channel}
      record.update_attributes(attributes)
      status = :ok #200
    end

    render :json => {"channel"=>record}.to_json, :status => status
  end


  api! 'Lookup a catalog'
  example 'GET api/router/12345-abcde-13434-abcde?channel=greatest

Response
{
    "catalogId": "catalogIdhash2"
}'
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
      status = :ok #302
    end

    render :json => {"catalogId"=>catalog_id}.to_json, :status => status
  end
end