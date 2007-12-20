module AssetCompressor
  
  # By default, Javascripts and stylesheets will only be compressed when in production.
  # However, this can be overridden by changing the value of AssetCompressor.environment
  # in one of your initializers.
  #
  # e.g. AssetCompressor.environment = "development" will enable compression in development.
  @@environment = "production"
  mattr_accessor :environment
  
  # Both javascript_include_compressed and stylesheet_link_compressed do very similar
  # things so they simply call a private third method, include_compressed.
  def javascript_include_compressed(compressed_file_name, *javascripts)
    include_compressed(:javascript, compressed_file_name, *javascripts)
  end
  
  def stylesheet_link_compressed(compressed_file_name, *stylesheets)
    include_compressed(:stylesheet, compressed_file_name, *stylesheets)
  end
  
  private
  
  # Returns a boolean whether to compress files or not.
  def compress?
    RAILS_ENV == environment
  end
  
  # Given a string like "jquery" or "jquery.js", return the full filename of "jquery.js".
  def javascript_path(path)
    !path[/\.js$/] ? "#{path}.js" : path
  end
  
  # Given a string like "scaffold" or "scaffold.css", return the full filename of 
  # "scaffold.css".
  def stylesheet_path(path)
    !path[/\.css$/] ? "#{path}.css" : path
  end
  
  def variables_for_javascript(compressed_file_name, scripts)
    extension = ".js"
    folder = "javascripts"
    compressed_file_name = javascript_path(compressed_file_name)
    scripts = scripts.map { |script| javascript_path(script) }
    include_tag = Proc.new { |script| javascript_include_tag(script) }
    [extension, folder, compressed_file_name, scripts, include_tag]
  end
  
  def variables_for_stylesheet(compressed_file_name, scripts)
    extension = ".css"
    folder = "stylesheets"
    compressed_file_name = stylesheet_path(compressed_file_name)
    scripts = scripts.map { |script| stylesheet_path(script) }
    include_tag = Proc.new { |script| stylesheet_link_tag(script) }
    [extension, folder, compressed_file_name, scripts, include_tag]
  end
  
  # The main method that handles both the compression of files and the returning of the
  # appropriate HTML tag.
  def include_compressed(type, compressed_file_name, *scripts)
    extension, folder, compressed_file_name, scripts, include_tag = send("variables_for_#{type}", compressed_file_name, scripts)
    
    if compress?
      if File.exists?(File.join(RAILS_ROOT, 'public', folder ,compressed_file_name))
        include_tag[compressed_file_name]
      else
        script_paths = scripts.map { |path| File.join(RAILS_ROOT, 'public', folder, path) }
  
        # Concatenate the files.
        `cat #{script_paths.join(" ")} > #{RAILS_ROOT}/tmp/#{compressed_file_name}`
        `java -jar #{File.join(RAILS_ROOT, 'vendor', 'plugins', 'asset_compressor', 'lib', 'yuicompressor-2.2.4.jar')} #{File.join(RAILS_ROOT, 'tmp', compressed_file_name)} -o #{File.join(RAILS_ROOT, 'public', folder, compressed_file_name)}`
        File.delete(File.join(RAILS_ROOT, 'tmp', compressed_file_name)) if File.exists?(File.join(RAILS_ROOT, 'tmp', compressed_file_name))
        include_tag[compressed_file_name]
      end
    else
      scripts.map { |script| include_tag[script] }.join
    end
  end
end