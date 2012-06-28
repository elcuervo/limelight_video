require 'test_helper'
require 'test_fixtures'

describe Limelight do
  it 'should validate minimal initializer' do
    assert_raises KeyError do
      Limelight.new
    end
  end

  it 'should validate tokens for authorized actions' do
    limelight = Limelight.new(organization: 'something', access_key: 'another')
    assert_raises KeyError do
      limelight.upload(sample_mp4_file, title: 'test')
    end
  end
end
