require 'fileutils'

require 'rubygems'
require 'yaml'

require 'slim' rescue nil

require File.dirname(__FILE__) + '/stasis/gems'

Stasis::Gems.activate %w(tilt)

$:.unshift File.dirname(__FILE__)

require 'stasis/plugin'
require 'stasis/plugin/helpers'

require 'stasis/context/action'
require 'stasis/context/controller'

require 'stasis/plugins/after'
require 'stasis/plugins/before'
require 'stasis/plugins/destination'
require 'stasis/plugins/helpers'
require 'stasis/plugins/ignore'
require 'stasis/plugins/layout'
require 'stasis/plugins/priority'
require 'stasis/plugins/render'

class Stasis
  
  attr_reader :controllers, :destination, :plugins, :root
  
  def initialize(root, destination=root+'/public')
    @destination = destination
    @root = root
    @controllers = Dir["#{root}/**/controller.rb"].inject({}) do |hash, path|
      context = Context::Controller.new(path, root)
      hash[context._[:dir]] = context
      hash
    end
  end
  
  def generate
    FileUtils.rm_rf(@destination)
    paths = Dir["#{root}/**/*"]
    paths.reject! { |p| File.basename(p) == 'controller.rb' || !File.file?(p) }
    @controllers, paths = trigger(:before_all, '*', controllers, paths)
    paths.each do |path|
      path_controller = @controllers[File.dirname(path)]
      @action = Context::Action.new(
        :path => path,
        :plugins => path_controller._[:plugins]
      )
      trigger(:before_render, path, @action, path)
      if @action._[:layout]
        layout_controller = @controllers[File.dirname(@action._[:layout])]
        @action._[:controller] = layout_controller
        view = @action.render(@action._[:layout]) do
          @action._[:controller] = path_controller
          output = @action.render(path)
          @action._[:controller] = layout_controller
          output
        end
      else
        @action._[:controller] = path_controller
        view = @action.render(path)
      end
      @action._[:controller] = nil
      trigger(:after_render, path, @action, path)
      if @action._[:destination]
        if @action._[:destination][0..0] == '/'
          dest = @action._[:destination]
        else
          rel_dir = File.dirname(path[root.length..-1])
          rel_dir += '/' unless rel_dir[-1..-1] == '/'
          dest = rel_dir + @action._[:destination]
        end
      else
        dest = path[root.length..-1]
      end
      dest = "#{@destination}#{dest}"
      Tilt.mappings.keys.each do |ext|
        if File.extname(dest)[1..-1] == ext
          dest = dest[0..-1*ext.length-2]
        end
      end
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, 'w') do |f|
        f.write(view)
      end
    end
  end

  def each_directory(path, &block)
    yield(root)
    dirs = File.dirname(path)[root.length+1..-1]
    if dirs
      dirs = dirs.split('/')
      dirs.each do |dir|
        yield("#{root}/#{dir}")
      end
    end
  end

  def trigger(type, path, *args, &block)
    if path == '*'
      controllers.values.each do |controller|
        args = controller._send_to_plugin_by_type(type, *args, &block)
      end
    else
      each_directory(path) do |dir|
        if controller = controllers[dir]
          @action._[:controller] = controller
          args = controller._send_to_plugin_by_type(type, *args, &block)
        end
      end
      @action._[:controller] = nil
    end
    args
  end
end