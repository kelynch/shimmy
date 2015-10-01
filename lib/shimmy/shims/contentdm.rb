require 'json'
require 'contentdm'
require 'iiif/presentation'
require 'recursive_open_struct'

module Shimmy

  module Shims
    # A shim for CONTENTdm
    class Contentdm < BaseShim

      @@hr_width = @@hr_height = 1400
      @@hr_scale = "25.000"

      attr_accessor :image

      def initialize(server_url, asset_url, collection_alias, item_id)
        harvester = ContentDm::Harvester.new(server_url)

        begin
          cdm_image = harvester.get_record(collection_alias,item_id)
        rescue
          fail "No OAI available for this record from CONTENTdm"
        end


        @image = RecursiveOpenStruct.new(cdm_image.metadata, :recurse_over_arrays => true)
        @image.asset_url = define_cdm_asset_url(asset_url, collection_alias, item_id)
      end

      def to_iiif(manifest_uri)
        manifest = IIIF::Presentation::Manifest.new(
        '@id' => manifest_uri,
        'label' => @image["dc.title"]
        )

        sequence = IIIF::Presentation::Sequence.new

        canvas = IIIF::Presentation::Canvas.new
        image_cdm = Shimmy::ImageRequestor.new(@image.asset_url)

        canvas.width = image_cdm.width
        canvas.height = image_cdm.height
        canvas.label = @image["dc.title"]

        canvas['@id'] = image_cdm.service_url
        anno = IIIF::Presentation::Annotation.new()
        ic = IIIF::Presentation::ImageResource.create_image_api_image_resource(resource_id: @image.asset_url, service_id: image_cdm.service_url)
        anno.resource = ic
        canvas.images << anno
        sequence.canvases << canvas

        manifest.sequences << sequence
        manifest.to_json(pretty: true)
      end

      def define_cdm_asset_url(asset_url, collection_alias, item_id)
        path = "#{asset_url}/utils/ajaxhelper/?CISOROOT=/#{collection_alias}&CISOPTR=#{item_id}&action=2&DMSCALE=#{@@hr_scale}&DMWIDTH=#{@@hr_width}&DMHEIGHT=#{@@hr_height}"
        path
      end

    end

  end
end
