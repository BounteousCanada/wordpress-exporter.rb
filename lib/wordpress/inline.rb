require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class Inline < Blog
        attr_reader :xml, :settings

        def initialize(xml, settings)
          @xml = xml
          @settings = settings
        end

        def inline_extractor
          output_logger.info 'Extracting inline images...'
          create_directory("#{settings.assets_dir}/image")
          extract_inline
        end

        private

        def extract_inline
          posts.each_with_object([]) do |post_xml, posts|
            content = post_xml.xpath('content:encoded').text
            doc = Nokogiri::HTML(content)
            images = doc.css('img').map {|i| extract_images(i)}
            attachment_extractor(images.reject(&:empty?), post_xml)
          end
        end

        def posts
          xml.search("//item[child::wp:post_type[text()[contains(., 'post')]]]").to_a
        end

        def extract_images(img)
          if img['src'].include? "wp-content/uploads"
            {
                id: '',
                name: filename(img['src']).split('.')[0],
                fileName: filename(img['src']),
                description: img['alt'].present? ? img['alt'] : '',
                url: img['src'].gsub("https", "http")
            }
          else
            ""
          end
        end

        def attachment_extractor(images, post_xml)
          images.each_with_index do |inline_image, key|
            image_id = image_id(post_xml, key)
            inline_image.merge!({id: image_id})
            unless inline_image[:url].nil?
              write_json_to_file("#{settings.assets_dir}/image/#{image_id}.json", inline_image)
              inline_image
            end
          end
        end

        def image_id(post_xml, key)
          "image_inline_#{post_xml.xpath('wp:post_id').text}_#{key}"
        end

        def filename(img_url)
          filename = img_url.split('wp-content/uploads/')
          filename[1].gsub("/", "-")
        end
      end
    end
  end
end
