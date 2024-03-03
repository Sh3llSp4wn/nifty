# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'
require 'find'

# Nifty namespace to prevent global clutter
module Nifty
  # the core nifty class that handles template to output generation
  class NiftyCore
    attr_accessor :sub_dict

    #=begin rdoc
    # static method that consumes the template configuration
    #=end
    def self.project_template_config(path)
      JSON.parse(File.read("#{path}/.nifty/nifty.json"))
    end

    # hate them un-named constants hanging around
    def self.nifty_base_dir
      '.nifty'
    end

    def self.nifty_replace_file_marker
      'REPLACE_'
    end

    def self.nifty_replace_file_marker_regex
      /REPLACE_/
    end

    def self.nifty_replace_in_file_marker
      'NIFTY_REPLACE_'
    end

    def self.nifty_replace_in_file_marker_regex
      /NIFTY_REPLACE_/
    end

    #=begin rdoc
    # create a new instance of nifty
    #=end
    def initialize(template_path, target_path)
      @selected_template = template_path
      @target_path = target_path
      @config = NiftyCore.project_template_config(template_path)
      @sub_dict = {}
    end

    #=begin rdoc
    # query the user for responses to the specified replacement keys
    #=end
    def interview
      # for all descriptions in the replacement hash
      @sub_dict = @config['replace'].map do |key, desc|
        # present the replacement key and description
        print "#{key} (#{desc}): "
        # return the replace key and the user unput
        val = $stdin.gets.chomp
        [key, val]
      end.to_h # convert to hash
    end

    def build_from_template
      copy_template
      replace_path_names
      replace_in_files
      delete_nifty_dir
    end

    def copy_template
      FileUtils.copy_entry(@selected_template, @target_path)
    end

    def substitute_path_name(path)
      # extract the replace key and val we will be operating with
      found_key, found_val = *@sub_dict.select do |key|
        path.basename.to_s.include?(key)
      end.flatten

      # construct a new path name after deleting REPLACE_
      # and substituting the value for the key
      Pathname.new(
        path.to_s.gsub(NiftyCore.nifty_replace_file_marker_regex, '').gsub(
          Regexp.new(
            Regexp.escape(found_key.to_s)
          ), found_val
        )
      )
    end

    def substitute_text(document_text)
      # so we can itterativly change the text
      # in case a document contains multiple keys
      text = document_text
      @sub_dict.each_key do |key|
        next unless text.include? "#{NiftyCore.nifty_replace_in_file_marker}#{key}"

        text = text.gsub(
          Regexp.new(
            NiftyCore.nifty_replace_in_file_marker + Regexp.escape(key)
          ), @sub_dict[key]
        )
      end
      # return final version of the text
      text
    end

    def replace_path_names
      Find.find(@target_path) do |path_str|
        path = Pathname.new path_str
        # stop searching this directory
        Find.prune if FileTest.directory?(path) && path.basename == NiftyCore.nifty_base_dir

        if path.basename.to_s.include? NiftyCore.nifty_replace_file_marker
          FileUtils.mv(path,
                       substitute_path_name(path))
        end
      end
    end

    def replace_in_files
      Find.find(@target_path) do |path_str|
        path = Pathname.new path_str
        # stop searching this directory
        Find.prune if FileTest.directory?(path) && path.basename == NiftyCore.nifty_base_dir
        # skip directories
        next if FileTest.directory?(path)

        # this is a normal file or a reference to a normal file
        # so do replacement
        text = File.read(path)
        new_contents = substitute_text text
        File.open(path, 'w') { |file| file.puts new_contents }
      end
    end

    def delete_nifty_dir
      FileUtils.remove_entry_secure("#{@target_path}/.nifty")
    end
  end
end
