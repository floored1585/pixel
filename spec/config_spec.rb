#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require_relative 'rspec'
require 'hashdiff'

describe Config do

  config_default = Config.new({})
  config_1 = JSON.load(CFG1)

  example = {
    grafana_if_dash: {
      setting: 'grafana_if_dash',
      value: 'test_if_dash_value',
      description: 'Link to the Grafana interface scripted dashboard',
      last_updated: 12345
    },
    grafana_dev_dash: {
      setting: 'grafana_dev_dash',
      value: 'test_dev_dash_value',
      description: 'Link to the Grafana device scripted dashboard',
      last_updated: 23456
    },
    stale_timeout: {
      setting: 'stale_timeout',
      value: 500,
      description: 'Number of seconds before polled data is considered stale',
      last_updated: 34567
    }
  }


  # Constructor
  describe '#new' do

    it 'should return' do
      expect(config_default).to be_a Config
    end

    it 'should return' do
      config = Config.new(example)
      expect(config).to be_a Config
    end

  end


  describe '#fetch_from_db' do

    it 'should return a Config' do
      expect(Config.fetch_from_db(db: DB)).to be_a Config
    end

  end


  describe '#settings' do

    context 'when checking grafana_if_dash' do
      it 'should be a ConfigItem' do
        expect(config_default.settings[:grafana_if_dash]).to be_a ConfigItem
      end
      it 'should be accurate' do
        expect(config_1.settings[:grafana_if_dash].value).to eql 'test_url'
      end
    end

    context 'when checking grafana_dev_dash' do
      it 'should be a ConfigItem' do
        expect(config_default.settings[:grafana_dev_dash]).to be_a ConfigItem
      end
      it 'should be accurate' do
        expect(config_1.settings[:grafana_dev_dash].value).to eql 'http://127.0.0.1'
      end
    end

    context 'when checking stale_timeout' do
      it 'should be a ConfigItem' do
        expect(config_default.settings[:stale_timeout]).to be_a ConfigItem
      end
      it 'should be accurate' do
        expect(config_1.settings[:stale_timeout].value).to eql 600
      end
    end

  end


  describe '#reload' do
    it 'should return a Config' do
      expect(Config.fetch).to be_a Config
    end
  end


  describe '#fetch_hash' do
    it 'should return a String' do
      expect(Config.fetch_hash).to be_a String
    end
  end


  describe '#fetch' do
    it 'should return a Config' do
      expect(Config.fetch).to be_a Config
    end
  end


  describe '#hash' do
    it 'should return an String' do
      expect(config_1.hash).to be_a String
    end
    it 'should be accurate' do
      expect(config_1.hash).to eql 'dbacf3307131dceef19a70a3e3dc6402'
    end
  end


  describe '#save' do

    it 'should exist with defaults after saving as new' do
      DB.transaction(:rollback=>:always, :auto_savepoint=>true) do
        DB[:global_config].truncate
        expect(Config.fetch_from_db(db: DB).save(DB)).to be_a Config
      end
    end

    it 'should be the same before and after saving' do
      DB.transaction(:rollback=>:always, :auto_savepoint=>true) do
        DB[:global_config].truncate

        db_config1 = Config.fetch_from_db(db: DB)
        db_config1.save(DB)
        db_config1 = JSON.parse(db_config1.to_json)
        db_config2 = JSON.parse(Config.fetch_from_db(db: DB).to_json)

        expect(db_config2).to eql db_config1
      end
    end
  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @config = Config.fetch_from_db(db: DB)
      end

      it 'should return a string' do
        expect(@config.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @config.to_json
        expect(JSON.load(json)).to be_a Config
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      config = Config.fetch_from_db(db: DB)

      json_config = config.to_json

      specify { expect(JSON.load(json_config).to_json).to eql json_config }

      it 'should not change' do
        hash = JSON.parse(JSON.load(CFG1).to_json)
        hash_expected = JSON.parse(CFG1)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

    end

  end

end
