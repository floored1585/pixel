require_relative 'rspec'
require 'hashdiff'

describe Instance do

  example = {
    hostname: 'test',
    ip: '127.0.0.1',
    core: true,
    poller: true,
    master: false,
    config_hash: 'abcdefg',
    last_updated: 12345
  }


  before :all do
    DB[:instance].insert(
      hostname: 'spec-test-poller',
      ip: '127.0.0.1',
      core: false,
      poller: true,
      master: false,
      config_hash: 'abcdefg',
      last_updated: 12345
    )
    DB[:instance].insert(
      hostname: 'spec-test-master',
      ip: '127.0.0.2',
      core: true,
      poller: true,
      master: true,
      config_hash: 'abcdefg',
      last_updated: 12345
    )
    DB[:instance].insert(
      hostname: 'spec-test',
      ip: '127.0.0.3',
      core: true,
      poller: true,
      master: false,
      config_hash: 'abcdefg',
      last_updated: 12345
    )
  end
  after :all do
    # Clean up DB
    DB[:instance].where(:hostname => 'spec-test-poller').delete
    DB[:instance].where(:hostname => 'spec-test-master').delete
    DB[:instance].where(:hostname => 'spec-test').delete
  end


  # Constructor
  describe '#new' do

    it 'should return' do
      instance = Instance.new
      expect(instance).to be_a Instance
    end

    it 'should return' do
      instance = Instance.new(
        hostname: 'test',
        ip: '127.0.0.1',
        core: true,
        poller: true,
        master: false,
        config_hash: 'abcdefg',
        last_updated: 12345
      )
      expect(instance).to be_a Instance
    end

  end


  describe '#delete' do
    after :each do
      DB[:instance].where(:hostname => 'iad1-pixel-dev1').delete
    end

    it 'should return 0 if nothing matches' do
      expect(Instance.delete(db: DB, hostname: 'nothing_should_match')).to equal 0
    end

    it 'should return 1 if something matches' do
      JSON.load(INSTANCE1).save(DB)
      expect(Instance.delete(db: DB, hostname: 'iad1-pixel-dev1')).to equal 1
    end
  end


  describe '#get_master' do

    it 'should return the master instance' do
      expect(Instance.get_master.hostname).to eql 'spec-test-master'
    end
  end


  describe '#fetch_from_db' do

    context 'when called with a bad hostname' do
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB, hostname: 'bad_hostname')).to be_a Array
      end
      it 'should return an empty array' do
        expect(Instance.fetch_from_db(db: DB, hostname: 'bad_hostname').length).to equal 0
      end
    end

    context 'when called with master' do
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB, master: true)).to be_a Array
      end
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB, master: true).first).to be_a Instance
      end
      it 'should be the right instance' do
        expect(Instance.fetch_from_db(db: DB, master: true).first.hostname).to eql 'spec-test-master'
      end
    end

    context 'when called with poller' do
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB, poller: true)).to be_a Array
      end
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB, poller: true).first).to be_a Instance
      end
      it 'should be the right instance' do
        expect(Instance.fetch_from_db(db: DB, poller: true).first.hostname).to eql 'spec-test-poller'
      end
    end

    context 'when called with nothing' do
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB)).to be_a Array
      end
      it 'should return an array' do
        expect(Instance.fetch_from_db(db: DB).first).to be_a Instance
      end
      it 'should be the right instance' do
        expect(Instance.fetch_from_db(db: DB).count).to equal 3
      end
    end

  end


  describe '#hostname' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be a string' do
      expect(instance_new.hostname).to be_a String
    end

    it 'should be empty when first initialized' do
      expect(instance_new.hostname).to be_empty
    end

    it 'should be accurate' do
      expect(instance.hostname).to eql 'iad1-pixel-dev1'
    end
  end


  describe '#ip' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be an IPAddr' do
      expect(instance_new.ip).to be_a IPAddr
    end

    it 'should be empty when first initialized' do
      expect(instance_new.ip).to eql IPAddr.new
    end

    it 'should be accurate' do
      expect(instance.ip).to eql IPAddr.new('172.18.0.17')
    end
  end


  describe '#core?' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be false' do
      expect(instance_new.core?.class).to equal FalseClass
    end

    it 'should be false when first initialized' do
      expect(instance_new.core?).to equal false
    end

    it 'should be accurate' do
      expect(instance.core?).to equal true
    end
  end


  describe '#master?' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be false' do
      expect(instance_new.master?.class).to equal FalseClass
    end

    it 'should be false when first initialized' do
      expect(instance_new.master?).to equal false
    end

    it 'should be accurate' do
      expect(instance.master?).to equal true
    end
  end


  describe '#poller?' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be false' do
      expect(instance_new.poller?.class).to equal FalseClass
    end

    it 'should be false when first initialized' do
      expect(instance_new.poller?).to equal false
    end

    it 'should be accurate' do
      expect(instance.poller?).to equal true
    end
  end


  describe '#config_hash' do
    instance = JSON.load(INSTANCE1)
    instance_new = Instance.new

    it 'should be a string' do
      expect(instance_new.config_hash).to be_a String
    end

    it 'should be empty when first initialized' do
      expect(instance_new.config_hash).to be_empty
    end

    it 'should be accurate' do
      expect(instance.config_hash).to eql '86dea7c86dca020e20be3ee483979766'
    end
  end


  describe '#update' do

    it 'should return an Instance' do
      expect(Instance.new.update!(settings: SETTINGS)).to be_a Instance
    end
    it 'should populate an empty Instance' do
      expect(Instance.new.update!(settings: SETTINGS).hostname).to eql Socket.gethostname
    end
    it 'should update an existing Instance' do
      instance = Instance.fetch_from_db(db: DB, hostname: 'spec-test').first
      instance.update!(settings: SETTINGS)

      expect(instance.hostname).to eql Socket.gethostname
      expect(instance.ip).to be_a IPAddr
      expect(instance.ip.to_s).to eql UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last}
      expect(instance.core?).to eql !!SETTINGS['this_is_core']
      expect(instance.poller?).to eql !!SETTINGS['this_is_poller']
      expect(instance.master?).to equal false
      expect(instance.config_hash).to eql Digest::MD5.hexdigest(Marshal::dump(SETTINGS))
    end

  end

  
  describe '#save' do

    after :each do
      DB[:instance].where(:hostname => 'iad1-pixel-dev1').delete
    end

    it 'should return nil if newly initialized' do
      expect(Instance.new.save(DB)).to eql nil
    end

    it 'should be the same before and after saving' do
      hash = JSON.parse(INSTANCE1)
      JSON.load(INSTANCE1).save(DB)

      db_instance = Instance.fetch_from_db(db: DB, hostname: 'iad1-pixel-dev1').first

      expect(JSON.parse(db_instance.to_json)).to eql hash
    end
  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @dev = Instance.new
      end

      it 'should return a string' do
        expect(@dev.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @dev.to_json
        expect(JSON.load(json)).to be_a Instance
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      instance = Instance.fetch_from_db(db: DB, hostname: 'spec-test')

      json_instance = instance.to_json

      specify { expect(JSON.load(json_instance).to_json).to eql json_instance }

      it 'should not change' do
        hash = JSON.parse(JSON.load(INSTANCE1).to_json)
        hash_expected = JSON.parse(INSTANCE1)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

    end

  end
=begin
  # save
  describe '#save' do

    after :each do
      # Clean up DB
      DB[:instance].where(:instance => 'test-v11u1-acc-y').delete
      DB[:instance].where(:instance => 'test-v11u2-acc-y').delete
    end


    it 'should not exist before saving' do
      expect(Instance.fetch('test-v11u1-acc-y')).to eql nil
    end

    it 'should return nil if no poll IP' do
      dev = Instance.new('test-v11u1-acc-y')
      expect(dev.save(DB)).to eql nil
    end

    it 'should save OK w/ name and IP' do
      dev = Instance.new('test-v11u1-acc-y', poll_ip: '1.2.3.4')
      expect(dev.save(DB)).to be_a Instance
    end

    it 'should exist after being saved' do
      JSON.load(DEV2_JSON).save(DB)
      dev = Instance.fetch('test-v11u1-acc-y')
      expect(dev).to be_a Instance
    end

    it 'should update without error' do
      JSON.load(DEV2_JSON).save(DB)
      JSON.load(DEV2_JSON).save(DB)
      dev = Instance.fetch('test-v11u1-acc-y')
      expect(dev).to be_a Instance
    end

    it 'should be identical before and after' do
      DB[:instance].where(:instance => 'test-v11u1-acc-y').delete
      JSON.load(DEV4_JSON).save(DB)
      fetched = JSON.parse(Instance.fetch('test-v11u2-acc-y', ['all']).to_json)
      expect(fetched).to eql JSON.parse(DEV4_JSON)
    end

    it 'should delete outdated components' do
      # Future dated last_updated times
      JSON.load(DEV2_JSON).save(DB)
      # Past dated last_updated times (this should delete everything except the instance)
      JSON.load(DEV3_JSON).save(DB)
      dev = Instance.fetch('test-v11u1-acc-y', ['all'])
      expect(dev.interfaces).to be_empty
      expect(dev.cpus).to be_empty
      expect(dev.fans).to be_empty
      expect(dev.memory).to be_empty
      expect(dev.psus).to be_empty
      expect(dev.temps).to be_empty
    end

  end


  # delete
  describe '#delete' do

    after :each do
      # Clean up DB
      DB[:instance].where(:instance => 'test-v11u1-acc-y').delete
    end


    it 'should return 1 if instance exists and is empty' do
      object = Instance.new('test-v11u1-acc-y', poll_ip: '1.2.3.4')
      object.save(DB)
      expect(object.delete(DB)).to eql 1
    end

    it 'should return the number of deleted objects' do
      JSON.load(DEV2_JSON).save(DB)
      object = Instance.fetch('test-v11u1-acc-y', ['all'])
      expect(object.delete(DB)).to eql 61
    end

    it "should return 0 if nonexistant" do
      object = Instance.new('test-v11u1-acc-y')
      expect(object.delete(DB)).to eql 0
    end

  end


  # to_json
  describe '#to_json and #json_create' do

    context 'when freshly created' do

      before(:each) do
        @dev = Instance.new('gar-test-1')
      end


      it 'should return a string' do
        expect(@dev.to_json).to be_a String
      end

      it 'should serialize and deserialize' do
        json = @dev.to_json
        expect(JSON.load(json)).to be_a Instance
        expect(JSON.load(json).to_json).to eql json
      end

    end


    context 'when populated' do

      c2960 = Instance.fetch(test_instances['Cisco 2960'], ['all'])
      c4948 = Instance.fetch(test_instances['Cisco 4948'], ['all'])
      cumulus = Instance.fetch(test_instances['Cumulus'], ['all'])
      ex = Instance.fetch(test_instances['Juniper EX'], ['all'])
      mx = Instance.fetch(test_instances['Juniper MX'], ['all'])
      f10_s4810 = Instance.fetch(test_instances['Force10 S4810'], ['all'])

      json_c2960 = c2960.to_json
      json_c4948 = c4948.to_json
      json_cumulus = cumulus.to_json
      json_ex = ex.to_json
      json_mx = mx.to_json
      json_f10_s4810 = f10_s4810.to_json

      specify { expect(JSON.load(json_c2960).to_json).to eql json_c2960 }
      specify { expect(JSON.load(json_c4948).to_json).to eql json_c4948 }
      specify { expect(JSON.load(json_cumulus).to_json).to eql json_cumulus }
      specify { expect(JSON.load(json_ex).to_json).to eql json_ex }
      specify { expect(JSON.load(json_mx).to_json).to eql json_mx }
      specify { expect(JSON.load(json_f10_s4810).to_json).to eql json_f10_s4810 }

      it 'should not change' do
        hash = JSON.parse(JSON.load(DEV1_JSON).to_json)
        hash_expected = JSON.parse(DEV1_JSON)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

      it 'should not change' do
        hash = JSON.parse(JSON.load(DEV2_JSON).to_json)
        hash_expected = JSON.parse(DEV2_JSON)
        expect(HashDiff.diff(hash, hash_expected)).to be_empty
      end

    end

  end


  # True integration tests
  describe '#poll' do
    #c2960 = Instance.new(test_instances['Cisco 2960']).populate.poll(worker: 't')
    #c4948 = Instance.new(test_instances['Cisco 4948']).populate.poll(worker: 't')
    #cumulus = Instance.new(test_instances['Cumulus']).populate.poll(worker: 't')
    #ex = Instance.new(test_instances['Juniper EX']).populate.poll(worker: 't')
    #mx = Instance.new(test_instances['Juniper MX']).populate.poll(worker: 't')
    #f10_s4810 = Instance.new(test_instances['Force10 S4810']).populate.poll(worker: 't')

    context 'on a Cisco 2960' do
      #'Cisco 2960' => 'gar-b11u18-acc-y',
    end

    context 'on a Cisco 4948' do
      #'Cisco 4948' => 'irv-i1u1-dist',
    end

    context 'on a Cumulus instance' do
      #'Cumulus' => 'aon-cumulus-2',
    end

    context 'on a Juniper EX' do
      #'Juniper EX' => 'gar-p1u1-dist',
    end

    context 'on a Juniper MX' do
      #'Juniper MX' => 'iad1-bdr-1',
    end

    context 'on a Force10 S4810' do
      #'Force10 S4810' => 'iad1-trn-1',
    end

  end

=end
end
