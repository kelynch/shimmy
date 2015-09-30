require 'faraday'

module Shimmy
  module JsonBlob

    def jsonify
      @blob ||= Hurley.post('https://jsonblob.com/api/jsonBlob') do |req|
        req.header[:content_type] = 'application/json'
        req.body = {}.to_json
      end
    end

    def blob_id
      jsonify unless @blob
      @blob.header['X-Jsonblob']
    end

    def blob_location
      jsonify unless @blob
      @blob.header['Location'].gsub('http:', 'https:')
    end

    def update_blob
      Hurley.put(blob_location) do |req|
        req.header[:content_type] = 'application/json'
        req.header[:accept] = 'application/json'
        req.body = to_iiif(blob_location)
      end
    end
  end
end
