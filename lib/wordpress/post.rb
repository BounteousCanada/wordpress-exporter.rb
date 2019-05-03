require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class Post < Blog
        attr_reader :xml, :settings

        def initialize(xml, settings)
          @xml = xml
          @settings = settings
        end

        def post_extractor
          output_logger.info 'Extracting posts...'
          create_directory("#{settings.entries_dir}/post")
          extract_posts
        end

        def post_id(post)
          "post_#{post.xpath('wp:post_id').text}"
        end

        private

        def extract_posts
          posts.each_with_object([]) do |post_xml, posts|
              normalized_post = extract_data(post_xml)
              write_json_to_file("#{settings.entries_dir}/post/#{post_id(post_xml)}.json", normalized_post)
              posts << normalized_post
          end
        end

        def posts
          xml.search("//item[child::wp:post_type[text()[contains(., 'post')]]]").to_a
        end

        def extract_data(post_xml)
          post_entry = basic_post_data(post_xml)
          assign_content_elements_to_post(post_xml, post_entry)
          post_entry
        end

        def author(post_xml)
          PostAuthor.new(xml, post_xml, settings).author_extractor
        end

        def tags(post_xml)
          PostCategoryDomain.new(xml, post_xml, settings).extract_tags
        end

        def categories(post_xml)
          PostCategoryDomain.new(xml, post_xml, settings).extract_categories
        end

        def basic_post_data(post_xml)
          {
            id: post_id(post_xml),
            title: title(post_xml),
            template: link_entry( {id: settings.contentful_post_template_id}),
            url: slug(post_xml),
            content: content(post_xml),
            publish_date: created_at(post_xml)
          }
        end

        def assign_content_elements_to_post(post_xml, post_entry)
          tags = link_entry(tags(post_xml))
          categories = link_entry(categories(post_xml))
          post_entry.merge!(author: link_entry(author(post_xml)))
          post_entry.merge!(tags: tags) unless tags.empty?
          post_entry.merge!(categories: categories) unless categories.empty?
        end

        def title(post_xml)
          post_xml.xpath('title').text
        end

        def url(post_xml)
          post_xml.xpath('link').text
        end

        def slug(post_xml)
          url(post_xml).sub(/https?:\/\/[^\/]+\/(.*)$/, '\1').chomp('/')
        end

        def content(post_xml)
          post_xml.xpath('content:encoded').text
        end

        def created_at(post_xml)
          ['pubDate','wp:post_date', 'wp:post_date_gmt'].each do |date_field|
            date_string = post_xml.xpath(date_field).text
            return Date.parse(date_string).strftime unless date_string.empty?
          end
          output_logger.warn "Post <#{post_id(post_xml)}> didn't have Creation Date - defaulting to #{Date.today}"
          Date.today
        end
      end
    end
  end
end
