require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class Tag < Blog
        attr_reader :xml, :settings, :tags

        def initialize(xml, settings, tags)
          @xml = xml
          @settings = settings
          @tags = tags
        end

        def tags_extractor
          output_logger.info 'Extracting blog tags...'
          create_directory("#{settings.entries_dir}/tag")
          extract_tags
        end

        private

        def extract_tags
          xml_tags.each_with_object([]) do |tag, xml_tags|
            write_json_to_file("#{settings.entries_dir}/tag/#{id(tag)}.json", extracted_data(tag))
          end unless settings.wordpress_modify_skip_old_tags

          additional_tags
        end

        def extracted_data(tag)
          {
              id: id(tag),
              display_name: name(tag),
              name: slug(tag)
          }
        end

        def xml_tags
          xml.xpath('//wp:tag').to_a
        end

        def id(tag)
          "tag_#{tag.xpath('wp:term_id').text}"
        end

        def slug(tag)
          tag.xpath('wp:tag_slug').text
        end

        def name(tag)
          tag.xpath('wp:tag_name').text
        end

        def additional_tags
          tags.each_with_index do |value, key|
            tag = {
                id: "tag_new_#{key}",
                display_name: value,
                name: value.downcase.gsub(' ', '-')
            }
            write_json_to_file("#{settings.entries_dir}/tag/tag_new_#{key}.json", tag)
          end
        end
      end
    end
  end
end
