require 'pathname'

module ThumbleMonks
  module AssetAutoInclude
    # I don't want to just blindly re-open AssetTagHelper.
    # Because of Ruby method lookup, I can't just include another module
    # into AssetTagHelper
    # So let's try a new compromise.
    AssetTagHelper = lambda do
      mattr_accessor :asset_autoinclude_options
      self.asset_autoinclude_options = {}
      asset_autoinclude_options[:asset_glob_patterns] = %w[controller %s-* *-%s *-%s-* %s]
      asset_autoinclude_options[:autoinclude_subdir] = "app"
      asset_autoinclude_options[:js_autoinclude_full_path] = Pathname.new("#{RAILS_ROOT}/public/javascripts/#{asset_autoinclude_options[:autoinclude_subdir]}")
      asset_autoinclude_options[:css_autoinclude_full_path] = Pathname.new("#{RAILS_ROOT}/public/stylesheets/#{asset_autoinclude_options[:autoinclude_subdir]}")

      def javascript_auto_include_tags
        files = autoloadable_files(asset_autoinclude_options[:js_autoinclude_full_path], "js")
        javascript_include_tag(*files)
      end

      def stylesheet_auto_include_tags
        files = autoloadable_files(asset_autoinclude_options[:css_autoinclude_full_path], "css")
        print_files = autoloadable_files(asset_autoinclude_options[:css_autoinclude_full_path], "print.css")
        print_files.push({:media => 'print'})

        stylesheet_link_tag(*files) << stylesheet_link_tag(*print_files)
      end
      
    private
      
      def autoloadable_files(search_base_path, extension)
        path = controller.controller_path
        search_glob = asset_glob(controller.action_name, extension)
        finds = search_dir(search_base_path, path, search_glob)
        finds.map { |loadable_file| "#{asset_autoinclude_options[:autoinclude_subdir]}/#{path}/#{loadable_file}"  }
      end
      
      def asset_glob(action_name, file_extension)
        alternated = asset_autoinclude_options[:asset_glob_patterns].map do |pattern|
          pattern % action_name
        end.join(',')
        "{#{alternated}}.#{file_extension}"
      end
      
      def search_dir(root, subdir, asset_glob_pattern)
        full = (root + subdir)
        Pathname.glob("#{root}/#{subdir}/#{asset_glob_pattern}").map do |matches|
          matches.relative_path_from(full)
        end
      end
      
    end # AssetTagHelper
  end   # AssetAutoInclude
end     # ThumbleMonks

ActionView::Helpers::AssetTagHelper.module_eval(&ThumbleMonks::AssetAutoInclude::AssetTagHelper)
