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
    javascripts.map! { |javascript| path_without_asset_id(javascript_path(javascript)) }
    include_compressed(path_without_asset_id(javascript_path(compressed_file_name)), *javascripts) { |sources| javascript_include_tag(*sources) }
  end
  
  def stylesheet_link_compressed(compressed_file_name, *stylesheets)
    stylesheets.map! { |stylesheet| path_without_asset_id(stylesheet_path(stylesheet)) }
    include_compressed(path_without_asset_id(stylesheet_path(compressed_file_name)), *stylesheets) { |sources| stylesheet_link_tag(*sources) }
  end
  
  private
  
  # Returns a boolean whether to compress files or not.
  def compress?
    RAILS_ENV == environment
  end
  
  # While Rails' javascript_path and stylesheet_path will nicely deal with filenames for us
  # it also appends an asset ID query string to paths (e.g. "base.css?123218234") which is
  # useful for client-side caching but renders the paths useless for normal IO (as they
  # are taken as part of the file name). This simple regular expression strips these
  # query strings.
  def path_without_asset_id(asset_path)
    asset_path[/^[^?]+/]
  end
  
  # The main method that handles both the compression of files and the returning of the
  # appropriate HTML tag.
  #
  # It takes the following two mandatory arguments and a block containing the tag helper for 
  # the asset type:
  # 
  # => compressed_file_name: the path to the asset relative from RAILS_ROOT/public
  # => *sources: one or more actual sources to be compressed.
  def include_compressed(compressed_file_name, *sources)

    # If we are to compress the files given (e.g. when in the correct environment) then do so.
    if compress?
      
      # If the compressed file does not already exist, create it.
      if !File.exists?(File.join(RAILS_ROOT, 'public', compressed_file_name))
        
        # Concatenate the files together in Ruby as Windows does not have cat.
        File.open(File.join(RAILS_ROOT, 'tmp', File.basename(compressed_file_name)), 'w') do |concatenated_file|
          sources.each do |source|
            File.open(File.join(RAILS_ROOT, 'public', source), 'r') do |file|
              concatenated_file << file.read
            end
          end
        end
        
        # Compress the concatenated file with YUI Compressor.
        `java -jar #{File.join(RAILS_ROOT, 'vendor', 'plugins', 'asset_compressor', 'lib', 'yuicompressor-2.2.4.jar')} #{File.join(RAILS_ROOT, 'tmp', File.basename(compressed_file_name))} -o #{File.join(RAILS_ROOT, 'public', compressed_file_name)}`
      
        # Delete the concatenated file.
        File.delete(File.join(RAILS_ROOT, 'tmp', File.basename(compressed_file_name))) if File.exists?(File.join(RAILS_ROOT, 'tmp', File.basename(compressed_file_name)))
      end
      
      # Include tag for compressed file.
      yield compressed_file_name
    else
      
      # Include tags for each file separately.
      yield *sources
    end
  end
end