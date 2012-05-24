require 'test_helper'
require 'test_fixtures'

describe Limelight do
  it 'should upload a video' do
    limelight = Limelight.new(
      organization: '889457f434f14057bdcc9a1f39bd9614',
      access_key: '5CIILY3Sw1P/qF2VHikRPXMEPdA=',
      secret: 'Frpgy2kz/xDAnrO3IBAWDRkNJ3s='
    )
    VCR.use_cassette("limelight upload media", match_requests_on: [:host, :path]) do
      video = limelight.upload('test', sample_mp4_file)
      video["media_id"].size.must_equal 32
    end
  end
end
