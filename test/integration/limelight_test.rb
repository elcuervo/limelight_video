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
    with_a_cassette("limelight upload media") do
      video = @limelight.upload(sample_mp4_file, title: 'test')
      video["media_id"].size.must_equal 32
    end
  end

  it 'should upload an io stream' do
    with_a_cassette("limelight upload io") do
      io = StringIO.new << File.read(sample_mp4_file)
      video = @limelight.upload(io, title: 'test', filename: sample_mp4_file)
      video["media_id"].size.must_equal 32
    end
  end

  it 'should create and list all the metadata' do
    with_a_cassette('create and list metadata') do
      @limelight.create_metadata("test")
      assert @limelight.list_metadata.include?("test")
      assert !@limelight.list_metadata.include?("none")
    end
  end

  it 'should upload a video with metadata' do
    with_a_cassette("limelight upload with metadata") do
      video = @limelight.upload(sample_mp4_file, title: 'test metadata', metadata: { internal_id: 10 })
      video["media_id"].size.must_equal 32

      media_info = @limelight.media_info(video["media_id"])
      assert media_info["custom_property"], "This media should have a custom property"
    end
  end

  it 'should delete an uploaded video' do
    with_a_cassette("limelight delete io") do
      video = @limelight.upload(sample_mp4_file, title: 'test')

      @limelight.delete_media(video["media_id"])
      media_info = @limelight.media_info(video["media_id"])
      assert media_info["errors"], "Unrecognized resource"
    end
  end

  it 'should create a channel' do
    with_a_cassette('create a channel') do
      channel = @limelight.create_channel('test')
      assert channel["channel_id"]

      channel = @limelight.publish_channel channel["channel_id"]
      assert_equal channel["state"], "Published"
    end
  end

  it 'should delete a channel' do
    with_a_cassette('delete a channel') do
      channel = @limelight.create_channel('deleted_channel')
      assert channel['channel_id']

      channel = @limelight.delete_channel(channel["channel_id"])
      assert channel.body["errors"]
    end
  end
end
