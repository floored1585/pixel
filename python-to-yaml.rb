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

require 'snmp/varbind'
require 'fileutils' 
require 'yaml'

def eval_mib_data(mib_hash)
  ruby_hash = mib_hash.
    gsub(':', '=>').                  # fix hash syntax
    gsub('(', '[').gsub(')', ']').    # fix tuple syntax
    sub('FILENAME =', 'filename =').  # get rid of constants
    sub('MIB =', 'mib =')
  mib = nil
  eval(ruby_hash)
  mib
end

def create_module(imp_file,exp_file)
  mib = eval_mib_data(IO.read(imp_file))
  if mib
    module_name = mib["moduleName"]
    raise "#{imp_file}: invalid file format; no module name" unless module_name
    if mib["nodes"]
      oid_hash = {}
      mib["nodes"].each { |key, value| oid_hash[key] = value["oid"] }
      if mib["notifications"]
        mib["notifications"].each { |key, value| oid_hash[key] = value["oid"] }
      end
      File.open(exp_file, 'w') do |file|
        YAML.dump(oid_hash, file)
        file.puts
      end
      #module_name
    else
      warn "*** No nodes defined in: #{module_file} ***"
      nil
    end
  else
    warn "*** Import failed for: #{module_file} ***"
    nil
  end
end

#create_module('./SNMPv2-SMI.python','./SNMPv2-SMI.yaml')
#create_module('./CISCO-SMI.python','./CISCO-SMI.yaml')
#create_module('./CISCO-PRODUCTS-MIB.python','./CISCO-PRODUCTS-MIB.yaml')
#create_module('./JUNIPER-SMI.python','./JUNIPER-SMI.yaml')
#create_module('./JNX-CHAS-DEFINES-MIB.python','./JNX-CHAS-DEFINES-MIB.yaml')
create_module('./F10-SMI.python','./F10-SMI.yaml')
create_module('./F10-PRODUCTS-MIB.python','./F10-PRODUCTS-MIB.yaml')
