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
            #Extract Images from img tags
            images = doc.css('img').map {|i| extract_images(i)}
            attachment_extractor(images.reject(&:empty?), post_xml)

            # Extract Images from a tags
            images = doc.css('a').map {|i| extract_anchors(i)}
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

        def extract_anchors(a)
          if a['href'].present? && a['href'].include?("wp-content/uploads") && a['href'].end_with?(".jpg",".jpeg",".png",".bmp",".gif")
            {
                id: '',
                name: filename(a['href']).split('.')[0],
                fileName: filename(a['href']),
                description: '',
                url: a['href'].gsub("https", "http")
            }
          else
            ""
          end
        end

        def attachment_extractor(images, post_xml)
          images.each do |inline_image|
            unless inline_image[:url].nil?
              filename_hash = Digest::MD5.hexdigest(filename(inline_image[:url]))
              image_id = image_id(post_xml, filename_hash)
              if File.exist?("#{settings.assets_dir}/image/#{image_id}.json")
                output_logger.info "Already exists, skipping #{image_id}"
              else
                inline_image.merge!({id: image_id})
                write_json_to_file("#{settings.assets_dir}/image/#{image_id}.json", inline_image)
                inline_image
              end
            end
          end
        end

        def image_id(post_xml, filename_hash)
          "image_inline_#{post_xml.xpath('wp:post_id').text}_#{filename_hash}"
        end

        def filename(img_url)
          filename = img_url.split('wp-content/uploads/')
          filename[1].gsub("/", "-")
        end
      end
    end
  end
end
