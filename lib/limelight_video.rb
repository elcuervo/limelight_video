require 'faraday'
require 'json'
require 'base64'
require 'openssl'
require 'mime/types'

class Limelight
  def initialize(options = {})
    @organization = options.fetch(:organization, ENV['LIMELIGHT_ORGANIZATION'])
    raise Limelight::MissingOrganization if !@organization

    @access_key = options.fetch(:access_key, ENV['LIMELIGHT_ACCESS_KEY'])
    @secret = options.fetch(:secret, ENV['LIMELIGHT_SECRET'])

    @host = 'http://api.videoplatform.limelight.com'
    @base_url = "/rest/organizations/#{@organization}/media"
    @client = Faraday.new(@host) do |builder|
      builder.request :multipart
      builder.adapter :net_http
    end
  end

  def upload(title, filename)
    raise Limelight::FileToUploadDoesNotExists if !File.exists?(filename)

    url = generate_signature('post', @base_url)
    mime = MIME::Types.type_for(filename)
    file = Faraday::UploadIO.new(filename, mime)
    response = @client.post(url, title: title, media_file: file)
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
    raise Limelight::MissingSecret    if !@secret
    raise Limelight::MissingAccessKey if !@access_key
  end

  def payload(params, method = 'get', path = @base_url)
    [
      method.downcase, URI.parse(@host).host, path,
      params.sort.map{ |arr| arr.join('=') }.join('&')
    ].join('|')
  end
end

class Limelight::MissingOrganization < StandardError
  def message
    'The :organization key is missing'
  end
end

class Limelight::MissingSecret < StandardError
  def message
    'The :secret key is missing'
  end
end

class Limelight::MissingAccessKey < StandardError
  def message
    'The :access_key key is missing'
  end
end

class Limelight::FileToUploadDoesNotExists < StandardError
  def message
    'The file cannot be found'
  end
end
