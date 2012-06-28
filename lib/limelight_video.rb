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
    @base_url = "/rest/organizations/#{@organization}/media"
    @client = Faraday.new(@host) do |builder|
      builder.request :multipart
      builder.adapter :net_http
    end
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

    url = generate_signature('post', @base_url)
    media_file = Faraday::UploadIO.new(file, mime, filename)
    options = { title: attributes.fetch(:title, 'Unnamed'), media_file: media_file}
    response = @client.post(url, options) do |req|
      req.options[:open_timeout] = 60*60
    end
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
