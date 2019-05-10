require 'active_support/core_ext/hash'
module Contentful
  class Configuration
    attr_reader :space_id,
                :data_dir,
                :collections_dir,
                :entries_dir,
                :assets_dir,
                :wordpress_xml,
                :contentful_post_template_id,
                :contentful_hero_template_id,
                :wordpress_modify_csv,
                :wordpress_modify_skip,
                :wordpress_modify_skip_old_tags,
                :wordpress_modify_skip_old_categories,
                :settings

    def initialize(settings)
      @settings = settings
      @data_dir = settings['data_dir']
      validate_required_parameters
      @wordpress_xml = settings['wordpress_xml_path']
      @collections_dir = "#{data_dir}/collections"
      @entries_dir = "#{data_dir}/entries"
      @assets_dir = "#{data_dir}/assets"
      @space_id = settings['space_id']
      @contentful_post_template_id = settings['contentful_post_template_id']
      @contentful_hero_template_id = settings['contentful_hero_template_id']
      @wordpress_modify_csv = settings['wordpress_modify_csv'].present? ? settings['wordpress_modify_csv'] : ''
      @wordpress_modify_skip = settings['wordpress_modify_skip'].present? ? settings['wordpress_modify_skip'] : false
      @wordpress_modify_skip_old_tags = settings['wordpress_modify_skip_old_tags'].present? ? settings['wordpress_modify_skip_old_tags'] : false
      @wordpress_modify_skip_old_categories = settings['wordpress_modify_skip_old_categories'].present? ? settings['wordpress_modify_skip_old_tags'] : false
      @space_id = settings['space_id']
    end

    def validate_required_parameters
      fail ArgumentError, 'Set PATH to data_dir. Folder where all data will be stored. View README' if settings['data_dir'].nil?
      fail ArgumentError, 'Set PATH to Wordpress XML file. View README' if settings['wordpress_xml_path'].nil?
    end
  end
end
