require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class HeroBanner < Blog
        attr_reader :xml, :settings

        def initialize(xml, settings)
          @xml = xml
          @settings = settings
        end

        def hero_extractor
          output_logger.info 'Extracting blog hero banners...'
          create_directory("#{settings.entries_dir}/hero_banner")
          extract_posts
        end

        private

        def extract_posts
          posts.each_with_object([]) do |post_xml, posts|
            thumbnail_id = thumbnail_id(post_xml)
            unless thumbnail_id == '' || thumbnail_id.nil?
              attachment_xml = xml.search("//item[child::wp:post_id[text()=#{thumbnail_id}]]").first
              unless attachment_xml.nil?
                normalized_post = extract_data(attachment_xml, post_xml)
                write_json_to_file("#{settings.entries_dir}/hero_banner/#{hero_id(attachment_xml)}.json", normalized_post)
                posts << normalized_post
              end
            end
          end
        end

        def posts
          xml.search("//item[child::wp:post_type[text()[contains(., 'post')]]]").to_a
        end

        def extract_data(attachment_xml, post_xml)
          {
              id: hero_id(attachment_xml),
              title: title(post_xml),
              template: link_entry({id: settings.contentful_hero_template_id}),
              image: link_asset({id: image_id(attachment_xml)}),
          }
        end

        def hero_id(attachment_xml)
          "hero_banner_#{attachment_xml.xpath('wp:post_id').text}"
        end

        def title(post_xml)
          post_xml.xpath('title').text
        end

        def image_id(attachment_xml)
          "image_#{attachment_xml.xpath('wp:post_id').text}"
        end
      end
    end
  end
end
