require 'omeka_client'
require 'iiif/presentation'
require "recursive_open_struct"


url = 'http://gamma.library.temple.edu/omeka_a11y/api'

module Shimmy
  module Shims
    # A shim for Flickr sets
    class Omeka < BaseShim

      attr_accessor :image

      def initialize(url, item_id)
        client = OmekaClient::Client.new(url)
        @image = get_all_files(client, {"item" => item_id})[0].data
      end

      def to_iiif(manifest_uri: nil )
        manifest = IIIF::Presentation::Manifest.new(
          '@id' => manifest_uri,
          'label' => @image.element_texts[0].text
        )

        sequence = IIIF::Presentation::Sequence.new


          canvas = IIIF::Presentation::Canvas.new
          canvas.width = @image.metadata.video.resolution_x.to_i
          canvas.height = @image.metadata.video.resolution_y.to_i
          canvas.label = @image.element_texts[0].text
          canvas['@id'] = Shimmy::ImageRequestor.new(@image.file_urls.original).iiifify
          anno = IIIF::Presentation::Annotation.new()
          ic = IIIF::Presentation::ImageResource.create_image_api_image_resource(resource_id: @image.file_urls.original, service_id: Shimmy::ImageRequestor.new(@image.file_urls.original).iiifify)
          anno.resource = ic
          canvas.images << anno
          sequence.canvases << canvas

        manifest.sequences << sequence
        manifest.to_json(pretty: true)
      end


      def get_all_files(client, query = {})
        response = client.get('files', nil, query = query).body

        parsed = JSON.parse(response)
        all_files = []
        parsed.each do |file_hash|
          all_files.push OmekaFile.new(self, file_hash)
        end
        return all_files
      end

    end



  class OmekaFile
    attr_accessor :data

    # Parse the data we got from the API into handy methods. All of the data
    # from the JSON returned by the API is available as RecursiveOpenStructs
    # through @data. The Dublin Core and Item Type Metadata fields are also
    # available though special methods of the form dc_title and itm_field.
    #
    # @param  hash [Hash] Uses the parsed hash from JSON api
    #
    def initialize(client, hash)
      @client = client
      @data = RecursiveOpenStruct.new(hash, :recurse_over_arrays => true)
#      @dublin_core = DublinCore.new(@data)
#      @item_type_metadata = ItemTypeMetadata.new(@data)
    end

    def item
      @client.get_item(@data.item.id)
    end


  end



  end
end
