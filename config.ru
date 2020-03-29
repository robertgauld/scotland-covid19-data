use Rack::Static,
  urls: ['/'],
  root: 'output',
  index: 'index.html'

run lambda { |env|
  [
    404,
    {
      'Content-Type'  => 'text/plain',
      'Cache-Control' => 'public, max-age=86400'
    },
    'Not found!'
  ]
}
