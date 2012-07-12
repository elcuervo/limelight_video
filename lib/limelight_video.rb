require 'faraday'
require 'json'
require 'base64'
require 'openssl'
require 'tempfile'
require 'mime/types'

class Limelight
  def initialize(options = {})
    @organization = options.fetch(:organization, ENV['LIMELIGHT_ORGANIZATION'])
    raise KeyError.new("organization") if !@organization

    @access_key = options.fetch(:access_key, ENV['LIMELIGHT_ACCESS_KEY'])
    @secret = options.fetch(:secret, ENV['LIMELIGHT_SECRET'])

    @host = 'http://api.videoplatform.limelight.com'
    @base_url = "/rest/organizations/#{@organization}"
    @base_media_url = "#{@base_url}/media"
    @base_channels_url = "#{@base_url}/channels"
    @client = Faraday.new(@host) do |builder|
      builder.request :url_encoded
      builder.adapter :net_http
    end
  end

  def media_info(media_id)
    response = @client.get("#{@base_media_url}/#{media_id}/properties.json")
    JSON.parse response.body
  end

  def upload(filename_or_io, attributes = {})
    case filename_or_io
      when String
        file = File.open(filename_or_io)
        filename = filename_or_io
        mime = MIME::Types.of(filename_or_io)
      when Tempfile, StringIO
        file = filename_or_io
        filename = attributes.fetch(:filename)
        mime = attributes[:type] || MIME::Types.of(filename)
      else
        raise Errno::ENOENT
      end

    media_file = Faraday::UploadIO.new(file, mime, filename)
    options = {
      title: attributes.fetch(:title, 'Unnamed'),
      media_file: media_file
    }
    if attributes[:metadata]
      custom_properties = attributes[:metadata]
      properties_to_create = custom_properties.keys.map(&:to_s) - list_metadata
      create_metadata(properties_to_create)
    end

    options[:custom_property] = attributes.fetch(:metadata, {})
    response = @client.post(upload_path, options) do |req|
      req.options[:open_timeout] = 60*60
    end

    JSON.parse response.body
  end

  def upload_url
    @host + upload_path
  end

  def upload_path
    generate_encoded_path('post', @base_media_url)
  end

  def create_channel(name)
    # http://api.videoplatform.limelight.com/rest/organizations/<org id>/channels.{XML,JSON}
    path = generate_encoded_path('post', @base_channels_url)
    response = @client.post(path, title: name)

    JSON.parse response.body
  end

  def publish_channel(id)
    path = generate_encoded_path('put', "#{@base_channels_url}/#{id}/properties")
    response = @client.put(path, state: "Published")

    JSON.parse response.body
  end

  def delete_channel(channel_id)
    # http://api.videoplatform.limelight.com/rest/organizations/<org id>/channels/<channel id>
    path = generate_encoded_path('delete', "#{@base_channels_url}/#{channel_id}")
    @client.delete(path)
  end

  def create_metadata(names)
    # http://api.videoplatform.limelight.com/rest/organizations/<org id>/media/properties/custom/<property name>
    Array(names).each do |name|
      path = generate_encoded_path('put', "#{@base_media_url}/properties/custom/#{name}")
      @client.put(path)
    end
  end

  def list_metadata
    # http://api.videoplatform.limelight.com/rest/organizations/<orgid>/media/properties/custom.{XML,JSON}
    response = @client.get("#{@base_media_url}/properties/custom.json")
    metadata = JSON.parse response.body
    metadata["custom_property_types"].map { |meta| meta["type_name"] }
  end

  def remove_metadata(names)
    # http://api.videoplatform.limelight.com/rest/organizations/<org id>/media/properties/custom/<property name>
    Array(names).each do |name|
      path = generate_encoded_path('delete', "#{@base_media_url}/properties/custom/#{name}")
      @client.delete(path)
    end
  end

  def delete_media(media_id)
    # http://api.videoplatform.limelight.com/rest/organizations/<org id>/media/<media id>
    path = generate_encoded_path('delete', "#{@base_media_url}/#{media_id}")
    @client.delete(path)
  end

  private

  def generate_encoded_path(method = 'get', path = @base_media_url)
    authorized_action

    params = { access_key: @access_key, expires: Time.now.to_i + 300 }
    signed = payload(params, method, path)
    signature = Base64.encode64(OpenSSL::HMAC.digest('sha256', @secret, signed))
    params[:signature] = signature.chomp

    "#{path}?#{Faraday::Utils.build_query(params)}"
  end

  def authorized_action
    raise KeyError.new("secret")     if !@secret
    raise KeyError.new("access_key") if !@access_key
  end

  def payload(params, method = 'get', path = @base_url)
    [
      method.downcase, URI.parse(@host).host, path,
      params.sort.map{ |arr| arr.join('=') }.join('&')
    ].join('|')
  end
end
