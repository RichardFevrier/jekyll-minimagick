require 'mini_magick'

module Jekyll
  module JekyllMinimagick

    class GeneratedImageFile < Jekyll::StaticFile

      def initialize(site, base, dir, name, preset)
        @site = site
        @base = base
        @dir  = dir
        @name = name
        @relative_path = File.join(*[@dir, @name].compact)
        @extname = File.extname(@name)
        @src_name = preset.delete('src_name')
        @commands = preset
      end

      def path
        File.join(@base, @dir, @src_name)
      end

      def write(dest)
        true
      end

    end

    class MiniMagickGenerator < Generator
      safe true

      def generate(site)
        return unless site.config['mini_magick']

        commands = []

        site.config['mini_magick'].each_pair do |name, preset|
          src_preset = preset.clone

          src_dir = src_preset.delete('source')
          Dir.glob(File.join(site.source, src_dir, "*.{png,jpg,jpeg,gif}")) do |source|
            basename = File.basename(source)
            extname = File.extname(basename)
            name = File.basename(basename, extname)
            size = src_preset['resize'].match(/\d*x\d*/)[0]
            dest_name = name + '-' + size + extname
            
            src_path = File.join(site.source, src_dir, basename)
            cache_path_without_filename = File.join(site.source, ".minimagick-cache", src_dir)
            cache_path = File.join(cache_path_without_filename, dest_name)
            dest_path = File.join(site.source, src_dir, dest_name)

            command = {'cache_path' => cache_path, 
                       'dest_path' => dest_path}

            commands << command

            FileUtils.mkdir_p cache_path_without_filename

            image = ::MiniMagick::Image.open(src_path)
            image.combine_options do |b|
              src_preset.each_pair do |command, arg|
                b.send command, arg
              end
            end
            image.write cache_path

            src_preset['src_name'] = basename

            site.static_files << GeneratedImageFile.new(site, site.source, src_dir, dest_name, src_preset)
          end
        end

        commands.each do |command|
          cache_path = command['cache_path']
          dest_path = command['dest_path']
          FileUtils.mv cache_path, dest_path
        end
      end
    end

  end
end
