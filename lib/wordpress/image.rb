require_relative 'post'

module Contentful
  module Exporter
    module Wordpress
      class Image < HeroBanner
        attr_reader :post, :settings

        def initialize(post, settings)
          @post = post
          @settings = settings
        end

        def attachment_extractor
          output_logger.info 'Extracting blog thumbnail attachment...'
          create_directory("#{settings.assets_dir}/image")
          asset = { id: attachment_id, name: attachment_description, fileName: attachment_filename, description: attachment_description, url: attachment_url }
          unless asset[:url].nil?
            write_json_to_file("#{settings.assets_dir}/image/#{attachment_id}.json", asset)
            asset
          end
        end

        private

        def attachment_url
          post.at_xpath('wp:attachment_url').text unless post.at_xpath('wp:attachment_url').nil?
        end

        def attachment_id
          "image_#{post.xpath('wp:post_id').text}"
          end

        def attachment_filename
          filename = post.xpath('.//wp:meta_key[contains(text(), "_wp_attached_file")]').first
          filename ? filename.parent.at_xpath('wp:meta_value').text.gsub("/", "-") : post.xpath('title').text
        end

        def attachment_description
          alt = post.xpath('.//wp:meta_key[contains(text(), "_wp_attachment_image_alt")]').first
          alt ? alt.parent.at_xpath('wp:meta_value').text : post.xpath('title').text
        end
      end
    end
  end
end
