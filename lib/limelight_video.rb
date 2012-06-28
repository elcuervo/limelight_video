require 'faraday'
require 'json'
require 'base64'
require 'openssl'
require 'mime/types'

class Limelight
  def initialize(options = {})
    @organization = options.fetch(:organization, ENV['LIMELIGHT_ORGANIZATION'])
    raise KeyError.new("organization") if !@organization

    @access_key = options.fetch(:access_key, ENV['LIMELIGHT_ACCESS_KEY'])
    @secret = options.fetch(:secret, ENV['LIMELIGHT_SECRET'])

    @host = 'http://api.videoplatform.limelight.com'
    @base_url = "/rest/organizations/#{@organization}/media"
    @client = Faraday.new(@host) do |builder|
      builder.request :multipart
      builder.adapter :net_http
    end
  end

  def upload(filename_or_io, attributes = {})
    filename = case filename_or_io
               when String
                 filename_or_io if File.exists?(filename_or_io)
               when StringIO
                 attributes.fetch(:filename)
               else
                 raise Errno::ENOENT
               end

    url = generate_signature('post', @base_url)
    mime = MIME::Types.type_for(filename)
    file = Faraday::UploadIO.new(filename_or_io, mime, filename)
    response = @client.post(url, title: attributes.fetch(:title, 'Unnamed'), media_file: file)
    JSON.parse response.body
  end

  private

  def generate_signature(method = 'get', path = @base_url)
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
