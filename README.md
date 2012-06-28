# Limelight Video

API interaction with the Limelight CDN

```ruby
require 'limelight_video'

limelight = Limelight.new(
  organization: 'your organization key',
  access_key: 'your access key',
  secret: 'your secret key',
)

# Upload a file
limelight.upload('~/Downloads/sample.mp4', title: 'My cool file')

# Uploads a stream, the filename is needed for the mime type in the upload
limelight.upload(io_stream, title: 'My cool file', filename: 'dancing_cat.mp4')
```
