require 'test_helper'
require 'test_fixtures'
require 'stringio'

describe Limelight do
  before do
    @limelight = Limelight.new(
      organization: '889457f434f14057bdcc9a1f39bd9614',
      access_key: '5CIILY3Sw1P/qF2VHikRPXMEPdA=',
      secret: 'Frpgy2kz/xDAnrO3IBAWDRkNJ3s='
    )
  end

  it 'should upload a video' do
    VCR.use_cassette("limelight upload media", match_requests_on: [:host, :path]) do
      video = @limelight.upload(sample_mp4_file, title: 'test')
      video["media_id"].size.must_equal 32
    end
  end

  it 'should upload an io stream' do
    VCR.use_cassette("limelight upload io", match_requests_on: [:host, :path]) do
      io = StringIO.new << File.read(sample_mp4_file)
      video = @limelight.upload(io, title: 'test', filename: sample_mp4_file)
      video["media_id"].size.must_equal 32
    end
  end
end
