# frozen_string_literal: true

# nifty_spec.rb

require 'nifty'
require 'fileutils'
require 'pathname'

RSpec.describe Nifty::NiftyCore do
  describe 'read_nifty_config' do
    it 'reads the .nifty/nifty.json file and consumes the configuration' do
      nifty_config = described_class.project_template_config('project_templates/c_clang')
      # config is a hash
      expect(nifty_config).to be_a(Hash)
      # config has a description key that refers to a string
      expect(nifty_config['description']).to be_a(String)
      # config has a replace key that refers to another hash
      expect(nifty_config['replace']).to be_a(Hash)
    end
    it 'expects the replace Hash to contain pairs of replacement keywords and descriptions' do
      nifty_config = described_class.project_template_config('project_templates/c_clang')
      replace_config = nifty_config['replace']
      # replace key refers to string -> string
      replace_config.each_key do |k|
        expect(k).to be_a(String)
        expect(replace_config[k]).to be_a(String)
      end
    end
  end

  describe 'interview' do
    it 'reads input from the user' do
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      # dork the prints that happen in interview
      allow($stdout).to receive(:write)
      # overwrite gets output with a test string
      allow($stdin).to receive(:gets).and_return('AAAAAAAA')
      # call the test function
      repl = core.interview
      expect(repl).to be_a(Hash)
      expect(repl['project_name']).to eq('AAAAAAAA')
    end
  end

  describe 'copy_template' do
    it 'copies the selected template to the target path' do
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      core.copy_template
      expect(File.exist?('/tmp/nifty_test/.nifty/nifty.json')).to eq(true)
      FileUtils.remove_entry_secure('/tmp/nifty_test')
    end
  end

  describe 'substitute_path_name' do
    it 'removes the REPLACE_ predicate and replaces the target string in the path name' do
      # construct the core and add a test sub_dict entry
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      core.sub_dict['project_name'] = 'test_test_test'

      # validate the function worked
      expect(
        core.substitute_path_name(Pathname.new('src/REPLACE_project_name.c'))
      ).to(
        eq(Pathname.new('src/test_test_test.c'))
      )
    end
  end

  describe 'replace_path_names' do
    it 'calculates the new path name and renames the file to it' do
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      core.sub_dict['project_name'] = 'test_test_test'
      core.copy_template
      core.replace_path_names
      expect(File.exist?('/tmp/nifty_test/src/test_test_test.c'))
      FileUtils.remove_entry_secure('/tmp/nifty_test')
    end
  end

  describe 'substitute_text' do
    it 'replaces text given the patterns in sub_dict' do
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      core.sub_dict['project_name'] = 'test_test_test'
      core.sub_dict['test_2'] = 'test_test_test_2'
      sub_text = core.substitute_text "\tNIFTY_REPLACE_project_name | | _ _ lol lol NIFTY_REPLACE_test_2"
      expect(sub_text).to eq("\ttest_test_test | | _ _ lol lol test_test_test_2")
    end
  end

  describe 'replace_in_files' do
    it 'replaces the replace keys found in files themselves' do
      core = described_class.new('project_templates/c_clang', '/tmp/nifty_test')
      core.sub_dict['project_name'] = 'test_test_test'
      core.copy_template
      core.replace_path_names
      core.replace_in_files
      data = File.read('/tmp/nifty_test/Makefile')
      expect(data.include?('test_test_test')).to eq(true)
      FileUtils.remove_entry_secure('/tmp/nifty_test')
    end
  end
end
