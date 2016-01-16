# instance.rb
#
require 'logger'
require 'json'
require 'digest/md5'
require 'ipaddr'
$LOG ||= Logger.new(STDOUT)

class Instance

  # Return the current master instance, or nil if there is no current master
  def self.get_master
    instance = API.get(
      src: 'instance',
      dst: 'core',
      resource: '/v2/instance/get_master',
      what: 'master instance'
    )
    return nil unless instance.class == Instance
    return instance
  end


  def self.fetch_from_db(db:, hostname: nil, master: nil, poller: nil)
    instances = []
    instance = db[:instance]
    instance = instance.where(:hostname => hostname) if hostname
    instance = instance.where(:master => true) if master
    instance = instance.where(:poller => true) if poller
    instance.each do |row|
      instances.push Instance.new(
        hostname: row[:hostname],
        ip: row[:ip],
        last_updated: row[:last_updated],
        core: row[:core],
        master: row[:master],
        poller: row[:poller],
        config_hash: row[:config_hash]
      )
    end
    return instances
  end


  def self.delete(db:, hostname:)
    DB[:instance].where(:hostname => hostname).delete
  end


  def initialize(hostname: nil, ip: nil, last_updated: nil, core: nil,
                 master: nil, poller: nil, config_hash: nil)
    @hostname = hostname
    @ip = IPAddr.new(ip) if ip
    @core = core
    @master = master
    @poller = poller
    @config_hash = config_hash
    @last_updated = last_updated
  end


  def hostname
    @hostname.to_s
  end


  def ip
    @ip || IPAddr.new
  end


  def core?
    !!@core
  end


  def master?
    !!@master
  end


  def poller?
    !!@poller
  end


  def config_hash
    @config_hash.to_s
  end


  def update!(db:, settings:)
    new_hostname = Socket.gethostname
    new_ip = IPAddr.new(UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last})
    new_core = true if settings['this_is_core']
    new_core ||= false
    new_master = true if (db[:instance].where(:master => true).count == 0) && new_core
    new_master ||= false
    new_poller = true if settings['this_is_poller']
    new_poller ||= false
    new_config_hash = Digest::MD5.hexdigest(Marshal::dump(settings))

    @hostname = new_hostname
    @ip = new_ip
    @core = new_core || false
    @master ||= new_master
    @poller = new_poller || false
    @config_hash = new_config_hash
    @last_updated = Time.now.to_i

    return self
  end


  def save(db)
    begin
      data = {}
      data[:hostname] = @hostname
      data[:ip] = @ip ? @ip.to_s : nil
      data[:core] = @core
      data[:master] = @master
      data[:poller] = @poller
      data[:config_hash] = @config_hash
      data[:last_updated] = @last_updated

      existing = db[:instance].where(:hostname => @hostname)
      if existing.update(data) != 1
        db[:instance].insert(data)
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("INSTANCE: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']['hostname'] = @hostname
    hash['data']['ip'] = @ip
    hash['data']['core'] = @core
    hash['data']['master'] = @master
    hash['data']['poller'] = @poller
    hash['data']['config_hash'] = @config_hash
    hash['data']['last_updated'] = @last_updated

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json['data']
    return Instance.new(
      hostname: data['hostname'],
      ip: data['ip'],
      core: data['core'],
      master: data['master'],
      poller: data['poller'],
      config_hash: data['config_hash'],
      last_updated: data['last_updated']
    )
  end


  private # All methods below are private!!


end
