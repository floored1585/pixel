Pixel
=============

Pixel is an open source network monitoring project maintained by [@floored1585](https://github.com/floored1585).

Pixel uses SNMP to monitor network equipment.  The API endpoint and user interface is designed to scale
horizontally behind a load balancer. Nodes can also be configured as dedicated pollers, only
interacting with the rest of the application via API calls. This allows the application to scale
extremely well as long as the database server is properly tuned.  A Pixel deployment can be scaled down
to a single VM running Pixel (poller and core), PostgreSQL, InfluxDB and Grafana, or can be widely
distributed with multiple instances of each component.

This project is severely lacking documentation at the moment, and the test suite will fail miserably
outside of a specifically crafted environment.  These are things that need work!

Installation
-------

* Baseline a Linux machine with [pixel-cookbook](https://github.com/floored1585/pixel-cookbook), or take the steps
in the [default recipe](https://github.com/floored1585/pixel-cookbook/blob/master/recipes/default.rb) manually.</li>
* Install and configure a PostgreSQL database either locally or on a different machine.
  * Create a database for Pixel and update Pixel's config/config.yaml appropriately.
  * Pixel will generate the database schema when it detects an empty database.
* Install Grafana either locally or on a different machine.
  * Copy the files in Pixel's `grafana` folder to `/usr/share/grafana/public/dashboards/` wherever
Grafana is installed.
* Install InfluxDB >= 0.9 either locally or on a different machine.
  * Create an InfluxDB database for Pixel.
* Deploy/clone Pixel to `var/www/pixel/current` on the machine you baselined with
[pixel-cookbook](https://github.com/floored1585/pixel-cookbook).
  * Modify `config/config.yaml` if necessary.
  * Restart Apache/Passenger.
  * Modify the `global_config` database table as appropriate *after* Pixel has started.

Adding Devices
-------

There is currently only one way of adding devices:

You must first configure the list of devices (and IPs) that Pixel should monitor in `config/hosts.yaml`.

Once you have valid YAML with devices and IPs, run `curl http://127.0.0.1/v2/devices/populate` on the
application server. This will update Pixel's database to match what is in `hosts.yaml` (it will add new
devices and remove devices no longer present in `hosts.yaml`).

Configuration
-------

There is currently no UI method for configuring Pixel.  Please take a look at the `global_config` table in the
PostgreSQL database.  This is currently where all the options live.

Logs / Troubleshooting
-------

Pixel is very much a work in progress at this point in time, so you may run into problems.
Application log data is written to the `messages.log` file at the application root, and
the Apache error log will likely contain useful information if you are running into error messages.

Contributing
============

Any form of contribution is welcome!  Feature requests, bug reports, pull requests, whatever!
If you add features, make sure there are tests for them, and if you change any code, make sure
the existing tests all pass _before_ creating a pull request. <b>NOTE: Tests currently are not in
the repository due to a number of issues (security and portability mostly).  I apologize --
fixing this is one of my top priorities.</b>

License
============

This project is licensed under the [GNU Affero GPL 3.0 License](http://www.gnu.org/licenses/agpl-3.0.en.html)
