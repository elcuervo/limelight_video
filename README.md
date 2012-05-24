# Limelight Video

API interaction with the Limelight CDN

```ruby
require 'limelight_video'

limelight = Limelight.new(
  organization: 'your organization key',
  access_key: 'your access key',
  secret: 'your secret key',
)

limelight.upload('my cool file', '~/Downloads/sample.mp4')
```
