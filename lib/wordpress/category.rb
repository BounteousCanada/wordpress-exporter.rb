require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class Category < Blog
        def initialize(xml, settings, categories)
          @xml = xml
          @settings = settings
          @categories = categories
        end

        def categories_extractor
          output_logger.info 'Extracting blog categories...'
          create_directory("#{settings.entries_dir}/category")
          extract_categories
        end

        private

        def extract_categories
          xml_categories.each_with_object([]) do |category, xml_categories|
            write_json_to_file("#{settings.entries_dir}/category/#{id(category)}.json", extracted_category(category))
          end unless settings.wordpress_modify_skip_old_categories

          additional_categories
        end

        def extracted_category(category)
          {
              id: id(category),
              display_name: nice_name(category),
              name: name(category)
          }
        end

        def xml_categories
          xml.xpath('//wp:category').to_a
        end

        def id(category)
          "category_#{category.xpath('wp:term_id').text}"
        end

        def nice_name(category)
          category.xpath('wp:category_nicename').text
        end

        def name(category)
          category.xpath('wp:cat_name').text
        end

        def additional_categories
          categories.each_with_index do |value, key|
            category = {
                id: "category_new_#{key}",
                display_name: value,
                name: value.downcase.gsub(' ', '-')
            }
            write_json_to_file("#{settings.entries_dir}/category/category_new_#{key}.json", category)
          end
        end
      end
    end
  end
end
