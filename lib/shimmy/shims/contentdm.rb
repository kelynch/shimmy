require 'json'
require 'contentdm'
require 'iiif/presentation'

server_url = 'https://server16002.contentdm.oclc.org/'
asset_url = 'https://server16002.contentdm.oclc.org/'
collection_alias = 'p16002coll19'

module Shimmy
  module Shims
    # A shim for CONTENTdm
    class Contentdm < BaseShim

      attr_accessor :image

      def initialize(server_url, asset_url, collection_alias, item_id)
        harvester = ContentDm::Harvester.new(server_url)
        cdm_image = harvester.get_record(collection_alias,item_id)
        @image = RecursiveOpenStruct.new(cdm_image.metadata, :recurse_over_arrays => true)
        @image.asset_url = define_cdm_asset_url(asset_url, collection_alias, item_id)
      end

      def to_iiif(manifest_uri: nil )
        manifest = IIIF::Presentation::Manifest.new(
        '@id' => manifest_uri,
        'label' => @image["dc.title"]
        )
        
        sequence = IIIF::Presentation::Sequence.new

        canvas = IIIF::Presentation::Canvas.new

        canvas.width = 600
        canvas.height = 1000
        canvas.label = @image["dc.title"]

        canvas['@id'] = Shimmy::ImageRequestor.new(@image.asset_url).iiifify
        anno = IIIF::Presentation::Annotation.new()
        ic = IIIF::Presentation::ImageResource.create_image_api_image_resource(resource_id: @image.asset_url, service_id: Shimmy::ImageRequestor.new(@image.asset_url).iiifify)
        anno.resource = ic
        canvas.images << anno
        sequence.canvases << canvas

        manifest.sequences << sequence
        manifest.to_json(pretty: true)
      end

      def define_cdm_asset_url(asset_url, collection_alias, item_id)
        hr_scale = "25.000"
        hr_width = hr_height = 1400
        path = "#{asset_url}/utils/ajaxhelper/?CISOROOT=/#{collection_alias}&CISOPTR=#{item_id}&action=2&DMSCALE=#{hr_scale}&DMWIDTH=#{hr_width}&DMHEIGHT=#{hr_height}"
        path
      end

    end




  end
end
