require 'digest'
require 'time'
require 'logger'
require 'csv'

module Contentful
  module Exporter
    module Wordpress
      class Blog
        attr_reader :xml, :settings

        def initialize(xml_document, settings)
          @xml = xml_document
          @settings = settings
        end

        def blog_extractor
          create_directory(settings.data_dir)
          extract_blog
          extract_authors
          extract_posts
          extract_hero_banners
          extract_categories
          extract_tags
        end

        def link_entry(entry_or_entries)
          link = ->(entry) {
            entry.keep_if {|key, _v| key if key == :id}
            entry.merge!(type: 'Entry')
          }

          if entry_or_entries.is_a? Array
            entry_or_entries.each(&link)
          else
            link.call(entry_or_entries)
          end
        end

        def link_asset(asset)
          asset.keep_if {|key, _v| key if key == :id}
          asset.merge!(type: 'File')
        end

        def create_directory(path)
          FileUtils.mkdir_p(path) unless File.directory?(path)
        end

        def write_json_to_file(path, data)
          File.open(path, 'w') do |file|
            file.write(JSON.pretty_generate(data))
          end
        end

        def output_logger
          Logger.new(STDOUT)
        end

        private

        def extract_blog
          output_logger.info('Extracting blog data...')
          create_directory("#{settings.entries_dir}/blog")
          posts.each_with_object([]) do |post_xml, posts|
            blog = extracted_data(post_xml)
            assign_extra_elements_to_blog(post_xml, blog)
            write_json_to_file("#{settings.entries_dir}/blog/#{blog_id(post_xml)}.json", blog)
          end
        end

        def extracted_data(post_xml)
          hero_id = hero_id(post_xml)
          {
              id: Digest::MD5.hexdigest(blog_id(post_xml)),
              title: title(post_xml),
              description: excerpt(post_xml),
              url: slug(post_xml),
              components: hero_id == '' ? link_entry([{id: post_id(post_xml)}]) : link_entry([{id: hero_id}, {id: post_id(post_xml)}])
          }
        end

        def assign_extra_elements_to_blog(post_xml, blog)
          thumbnail = thumbnail_attachment(post_xml)
          blog.merge!(thumbnail: link_asset(thumbnail)) unless thumbnail.nil?
        end

        def thumbnail_attachment(post_xml)
          thumbnail_id = thumbnail_id(post_xml)
          if thumbnail_id != '' && !thumbnail_id.nil?
            thumbnail = xml.search("//item[child::wp:post_id[text()=#{thumbnail_id}]]").first
            Image.new(thumbnail, settings).attachment_extractor unless thumbnail.nil?
          end
        end

        def blog_id(post_xml)
          "blog_#{post_xml.xpath('wp:post_id').text}"
        end

        def post_id(post_xml)
          "post_#{post_xml.xpath('wp:post_id').text}"
        end

        def thumbnail_id(post_xml)
          thumbnail = post_xml.xpath('.//wp:meta_key[contains(text(), "_thumbnail_id")]').first
          thumbnail ? thumbnail.parent.at_xpath('wp:meta_value').text : ''
        end

        def hero_id(post_xml)
          post_id = thumbnail_id(post_xml)
          if post_id != '' && !post_id.nil?
            hero = xml.search("//item[child::wp:post_id[text()=#{post_id}]]").first
            hero ? "hero_banner_#{hero.xpath('wp:post_id').text}" : ''
          else
            ''
          end
        end

        def excerpt(post_xml)
          truncate(post_xml.xpath('content:encoded').text,55)
        end

        def truncate(content, max)
          doc = Nokogiri::HTML(content)
          content = doc.xpath("//text()").remove.text.split(" ")
          if content.length > max
            truncated = ""
            collector = 0
            content.each do |word|
              word = word + " "
              collector+=1
              truncated << word if collector.to_i < max
            end
            truncated = truncated.strip.chomp(",").concat("...")
          else
            truncated = content
          end
          return truncated
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

        def posts
          xml.search("//item[child::wp:post_type[text()[contains(., 'post')]]]").to_a
        end

        def extract_authors
          Author.new(xml, settings).author_extractor
        end

        def extract_posts
          Post.new(xml, settings).post_extractor
        end

        def extract_hero_banners
          HeroBanner.new(xml, settings).hero_extractor
        end

        def extract_categories
          Category.new(xml, settings).categories_extractor
        end

        def extract_tags
          Tag.new(xml, settings).tags_extractor
        end
      end
    end
  end
end
