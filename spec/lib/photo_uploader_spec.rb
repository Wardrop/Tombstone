require 'carrierwave'
require 'carrierwave/sequel'

require_relative '../spec_helper'
require_relative '../../app/lib/photo_uploader'

module Tombstone

  current_dir = File.dirname(__FILE__)

  CarrierWave.configure do |config|
    config.store_dir = '/tmp'
    config.cache_dir = '/tmp/cache'
  end

  describe PhotoUploader do

    it "should store a simple file" do
      file = File.open(File.join(current_dir, '/example.jpg'))
      uploader = PhotoUploader.new
      uploader.store!(file)
      uploader.store_path.should == '/tmp/example.jpg'
    end
  end

end