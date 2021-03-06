require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'json'

require_relative 'blog'
require_relative 'author'
require_relative 'post'
require_relative 'hero_banner'
require_relative 'image'
require_relative 'inline'
require_relative 'category'
require_relative 'tag'
require_relative 'post_category_domain'
require_relative 'post_author'

module Contentful
  module Exporter
    module Wordpress
      class Export
        attr_reader :wordpress_xml, :settings

        def initialize(settings)
          @settings = settings
          @wordpress_xml = Nokogiri::XML(File.open(settings.wordpress_xml))
        end

        def export_blog
          Blog.new(wordpress_xml, settings).blog_extractor
        end

        def export_inline
          Inline.new(wordpress_xml, settings).inline_extractor
        end
      end
    end
  end
end
