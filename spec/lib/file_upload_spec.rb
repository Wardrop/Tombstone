require 'carrierwave'
require 'carrierwave/sequel'

require_relative '../../app/lib/file_uploader'

module Tombstone

  current_dir = File.dirname(__FILE__)

  CarrierWave.configure do |config|
    config.store_dir = '/tmp'
    config.cache_dir = '/tmp/cache'
  end

  describe FileUploader do

    it "should store a simple file" do
      file = File.open(File.join(current_dir, '/example.jpg'))
      file_uploader = FileUploader.new
      file_uploader.store!(file)
      file_uploader.store_path.should == 'tmp/example.jpg'
    end
  end

end