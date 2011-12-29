# sap_file_spec.rb
require 'spec_helper'

describe SapFile, "#tags" do
  it "returns all tags for .tags" do
    sapfile = SapFile.create(:name =>"myFile",:filepath=>"somepathinthefilesystem")
    sapfile.meta_tags << MetaTag.create(:name=>'a tag 1')
    sapfile.meta_tags << MetaTag.create(:name => 'a tag 2')
    sapfile.meta_tags.count == 2
  end
end