require 'vcr'
require "minitest/autorun"
require 'limelight_video'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/cassettes'
  c.hook_into :fakeweb
end

def with_a_cassette(name, &block)
  VCR.use_cassette(name, match_requests_on: [:host, :path], &block)
end
