require 'contentdm'
require 'iiif/presentation'

url = 'https://server16002.contentdm.oclc.org/'
collection_alias = 'p16002coll19'

module Shimmy
  module Shims
    # A shim for CONTENTdm
    class Contentdm < BaseShim

      attr_accessor :image

      def initialize(url, collection_alias, item_id)
        harvester = ContentDm::Harvester.new(url)
        cdm_image = harvester.get_record(collection_alias,item_id)
        @image = cdm_image
      end

      def to_iiif(manifest_uri: nil )
        manifest = IIIF::Presentation::Manifest.new(
        '@id' => manifest_uri,
        'label' => @image.metadata["dc.title"]
        )

        sequence = IIIF::Presentation::Sequence.new

        canvas = IIIF::Presentation::Canvas.new

        canvas.width = 600
        canvas.height = 1000
        canvas.label = @image.metadata["dc.title"]
        canvas['@id'] = Shimmy::ImageRequestor.new(@image.metadata["dc.identifier"]).iiifify
        anno = IIIF::Presentation::Annotation.new()
        ic = IIIF::Presentation::ImageResource.create_image_api_image_resource(resource_id: @image.metadata["dc.identifier"], service_id: Shimmy::ImageRequestor.new(@image.metadata["dc.identifier"]).iiifify)
        anno.resource = ic
        canvas.images << anno
        sequence.canvases << canvas

        manifest.sequences << sequence
        manifest.to_json(pretty: true)
      end

    end




  end
end
