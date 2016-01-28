require_relative 'rspec'
require 'hashdiff'

describe ConfigItem do

  config_item_1 = JSON.load(CFG_ITEM1)
  config_item_string = ConfigItem.new(
    table_name: 'global_config', setting: 'grafana_if_dash', value: 'string_config_item',
    type: 'String', description: 'String ConfigItem', last_updated: 12345
  )
  config_item_int = ConfigItem.new(
    table_name: 'global_config', setting: 'grafana_if_dash', value: '54321',
    type: 'Integer', description: 'Int ConfigItem', last_updated: 23456
  )
  config_item_false = ConfigItem.new(
    table_name: 'global_config', setting: 'grafana_if_dash', value: 'false',
    type: 'Boolean', description: 'Bool ConfigItem', last_updated: 34567
  )
  config_item_true = ConfigItem.new(
    table_name: 'global_config', setting: 'grafana_if_dash', value: 'true',
    type: 'Boolean', description: 'Bool ConfigItem', last_updated: 34567
  )
  JSON.load(CFG_ITEM1).save(DB)

  example_data = {
    table_name: 'global_config',
    setting: 'grafana_if_dash',
    value: 'test_if_dash_value',
    type: 'String',
    description: 'Link to the Grafana interface scripted dashboard',
    last_updated: 12345
  }


  # Constructor
  describe '#new' do

    it 'should return' do
      config_item = ConfigItem.new(
        table_name: 'global_config',
        setting: 'grafana_if_dash',
        value: 'test_if_dash_value',
        type: 'String',
        description: 'Link to the Grafana interface scripted dashboard',
        last_updated: 12345
      )
      expect(config_item).to be_a ConfigItem
    end

  end


  # Value
  describe '#value' do
    it 'should be the right class when a String' do
      expect(config_item_string.value).to be_a String
    end
    it 'should be accurate when a String' do
      expect(config_item_string.value).to eql 'string_config_item'
    end
    it 'should be the right class when a number' do
      expect(config_item_int.value).to be_a Integer
    end
    it 'should be accurate when a number' do
      expect(config_item_int.value).to eql 54321
    end
    it 'should be the right class when false' do
      expect(config_item_false.value).to be_a FalseClass
    end
    it 'should be the right class when true' do
      expect(config_item_true.value).to be_a TrueClass
    end
  end


  # last_updated
  describe '#last_updated' do
    it 'should be an Integer' do
      expect(config_item_string.last_updated).to be_a Integer
    end
    it 'should be accurate' do
      expect(config_item_int.last_updated).to eql 23456
    end
  end


  # description
  describe '#description' do
    it 'should be a String' do
      expect(config_item_string.description).to be_a String
    end
    it 'should be accurate' do
      expect(config_item_int.description).to eql 'Int ConfigItem'
    end
  end


  describe '#save' do

    it 'should be the same before and after saving' do
      DB.transaction(:rollback=>:always, :auto_savepoint=>true) do
        DB[:global_config].truncate
        hash = JSON.parse(CFG_ITEM1)
        JSON.load(CFG_ITEM1).save(DB)

        db_config_item = ConfigItem.fetch_from_db(db: DB, table: 'global_config', setting: 'grafana_if_dash')

        expect(JSON.parse(db_config_item.values.first.to_json)).to eql hash
      end
    end
  end


  # to_json
  describe '#to_json and #json_create' do

    it 'should return a string' do
      expect(JSON.load(CFG_ITEM1).to_json).to be_a String
    end

    it 'should serialize and deserialize' do
      json = JSON.load(CFG_ITEM1).to_json
      expect(JSON.load(json)).to be_a ConfigItem
      expect(JSON.load(json).to_json).to eql json
    end

  end

end
