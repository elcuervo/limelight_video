require 'test_helper'
require 'test_fixtures'
require 'stringio'
require 'json'
require 'date'

describe Limelight do
  before do
    @limelight = Limelight.new(
       organization: 'dde8e72013ba44768e764e1bff217a5a',
       access_key: 'DaYkT4MO0DwIdTk1Af9XmHFHFGM=',
       secret: '4/y6UgzsDsJSqqrIh2I3EFEOTYA='
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
      io.rewind
      video = @limelight.upload(io, title: 'test', filename: 'test.mp4')
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

  it 'should update an uploaded video' do
    with_a_cassette('update video information') do
      video = @limelight.upload(sample_mp4_file, title: 'test')
      media_info = @limelight.media_info(video["media_id"])
      assert_equal media_info["description"], nil
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
      channel = @limelight.publish_channel channel["channel_id"]
      assert channel['channel_id']


      channel = @limelight.delete_channel(channel["channel_id"])
      assert channel.status, 200
    end
  end

  it "should update a channel's name" do
    with_a_cassette('update a channel name') do
      channel = @limelight.create_channel('GLaDOS Channel')
      assert channel['title'], 'GLaDOS Channel'

      properties = {title: 'Aperture Science Channel'}

      channel = @limelight.update_channel(channel['channel_id'], properties)
      assert channel['title'], 'Aperture Science Channel'
    end
  end

  it "should get media statistics" do
    with_a_cassette('media statistics load') do
      video = @limelight.upload(sample_mp4_file, title: 'test')
      statistics = @limelight.analytics_for_media(video["media_id"])
    end
  end

  it "should get most played media" do
    with_a_cassette('most played media') do
      start_time = Date.new(2013,2,1).to_time.to_i    
      end_time = Date.new(2013,3,1).to_time.to_i

      top_media = @limelight.most_played_media(start_time, end_time)
    end
  end

  it "should add a video to a channel" do
    with_a_cassette('add video to channel') do
      video = @limelight.upload(sample_mp4_file, title: 'test')
      video["media_id"].size.must_equal 32

      channel = @limelight.create_channel('new_channel')
      channel = @limelight.publish_channel channel["channel_id"]
      assert channel['channel_id']

      @limelight.add_media_to_a_channel(video['media_id'], channel['channel_id'])
      channel_media = @limelight.list_channel_media(channel['channel_id'])

      # assert channel_media["media_list"][0]['media_id'], video["media_id"]
      # There's an issue here, that we can't check for a media's presence in a
      # channel until it's been processed on the Limelight Platform
    end
  end
end
