Gem::Specification.new do |s|
  s.name              = "limelight"
  s.version           = "0.0.1"
  s.summary           = "Limelight video client"
  s.description       = "Interact with the Limelight CDN platform"
  s.authors           = ["elcuervo"]
  s.email             = ["yo@brunoaguirre.com"]
  s.homepage          = "http://github.com/elcuervo/limelight_video"
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files test`.split("\n")

  s.add_dependency("faraday", "~> 0.8.0")
  s.add_dependency("mime-types", "~> 1.18")

  s.add_development_dependency("minitest", "~> 3.0.0")
  s.add_development_dependency("fakeweb", "~> 1.3.0")
  s.add_development_dependency("vcr", "~> 2.1.0")
end
