require_relative 'blog'

module Contentful
  module Exporter
    module Wordpress
      class Post < Blog
        attr_reader :xml, :settings, :inline_images, :modify, :tags, :categories

        def initialize(xml, settings, modify, tags, categories)
          @xml = xml
          @settings = settings
          @modify = modify
          @tags = tags
          @categories = categories
          @inline_images = {}

          if File.exist? "#{settings.data_dir}/all_assets.csv"
            CSV.foreach("#{settings.data_dir}/all_assets.csv", :headers => true, :header_converters => :symbol, :converters => :all) do |row|
              @inline_images[row.fields[0]] = Hash[row.headers.zip(row.fields)]
            end
          end
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
            if settings.wordpress_modify_csv == '' || settings.wordpress_modify_skip == false || modify[post_xml.xpath('wp:post_id').text  ].present?
              normalized_post = extract_data(post_xml)
              write_json_to_file("#{settings.entries_dir}/post/#{post_id(post_xml)}.json", normalized_post)
              posts << normalized_post
            end
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

        def get_tags(post_xml)
          PostCategoryDomain.new(xml, post_xml, settings, modify, tags, categories).extract_tags
        end

        def get_categories(post_xml)
          PostCategoryDomain.new(xml, post_xml, settings, modify, tags, categories).extract_categories
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
          generated_tags = link_entry(get_tags(post_xml))
          generated_categories = link_entry(get_categories(post_xml))
          post_entry.merge!(author: link_entry(author(post_xml)))
          post_entry.merge!(tags: generated_tags) unless generated_tags.empty?
          post_entry.merge!(categories: generated_categories) unless generated_categories.empty?
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
          replace_inline(post_xml.xpath('content:encoded').text.gsub(/\n/, "\n<br />"), post_xml)
        end

        def created_at(post_xml)
          ['pubDate','wp:post_date', 'wp:post_date_gmt'].each do |date_field|
            date_string = post_xml.xpath(date_field).text
            return Date.parse(date_string).strftime unless date_string.empty?
          end
          output_logger.warn "Post <#{post_id(post_xml)}> didn't have Creation Date - defaulting to #{Date.today}"
          Date.today
        end

        def replace_inline(content, post_xml)
          doc = Nokogiri::HTML.fragment(content)
          doc.css("img").each_with_index do |img, key|
            if img['src'].include? "wp-content/uploads"
              filename_hash = Digest::MD5.hexdigest(filename(img['src']))
              img_id = "image_inline_#{post_xml.xpath('wp:post_id').text}_#{filename_hash}"
              if inline_images[img_id].present?
                output_logger.info 'Replacing inline image...'
                img.attributes["src"].value = inline_images[img_id][:url]
              end
            end
          end

          doc.css("a").each_with_index do |a, key|
            if a['href'].present? && a['href'].include?("wp-content/uploads") && a['href'].end_with?(".jpg",".jpeg",".png",".bmp",".gif")
              filename_hash = Digest::MD5.hexdigest(filename(a['href']))
              a_id = "image_inline_#{post_xml.xpath('wp:post_id').text}_#{filename_hash}"
              if inline_images[a_id].present?
                output_logger.info 'Replacing inline anchor image...'
                a.attributes["href"].value = inline_images[a_id][:url]
              end
            end
          end
          doc.to_html
        end

        def filename(img_url)
          filename = img_url.split('wp-content/uploads/')
          filename[1].gsub("/", "-")
        end
      end
    end
  end
end
