[![Build Status](https://travis-ci.org/sbp-cookbooks/mercury.svg?branch=master)](https://travis-ci.org/sbp-cookbooks/mercury)

# Mercury Global Loadbalancer Cookbook

Installs and configures Mercury Global Loadbalancer.

## What is Mercury?

Mercury is a Global loadbalancer, designed to add a dns based loadbalancing layer on top of its internal loadbalancer or 3rd pary loadbalancers such as cloud services
This makes mercury able to loadbalance across multiple cloud environments using dns, while keeping existing cloud loadbancer sollutions in place

* Source: https://github.com/schubergphilis/mercury
* Binaries: https://github.com/schubergphilis/mercury/releases
* Docs: http://mercury-global-loadbalancer.readthedocs.io/en/latest/

## Requirements

- Chef 12.5+

### Platforms

- RHEL 6+, CentOS6+
- RHEL 7+, CentOS7+

## Documentation

### Install

Include the default recipe

### Configuration items

```
default['mercury']['settings'] = {
    manage_network_interfaces: "(yes|no)" -- allow mercury to add vip's to the network interfaces (default: yes) - required for internal proxy or for haproxy who does not add vip's
	enable_proxy: "(yes|no)"	-- use internal proxy for loadbalancing (default: yes) - not needed for external proxy programs, or dns only setup
}

default['mercury']['logging'] = {
	level: "(debug|info|warn|error)" -- log level
	output: "(stdout|file)"	-- log output
}

default['mercury']['cluster'] = {
	name: "" -- cluster group name
	binding: "myhost" -- ip/interface to bind on, also acts as cluster name
    settings: {
		connection_timeout: 10, -- connection timeout for cluster nodes
  		connection_retry_count: 10, -- connection retry for cluster nodes
  		connection_retry_interval: 10, -- connection retry interval for cluster nodes
  		ping_interval: 10, -- ping interval for cluster nodes
  		ping_timeout: 10, -- time to wait for reply before discarding cluster node
  		port: 9000, -- port for cluster communications
  		tls: { -- see tls settings below for more details
			insecureskipverify: true
		}
	},
    nodes: [
		{
			search: "recipe:chef_recipe", -- let chef find the remote nodes based on search
			port: 80 -- connect to port 80 of this node
		},
	]
}


default['mercury']['dns'] = {
	binding: 'myhost' -- ip to bind on
  	port: 53 -- port to listen on for dns queries
  	allowed_requests: [ "A", "AAAA" ] -- what records to respond to (default is to allow most requests)
}

default['mercury']['web'] = {
	binding: 'myhost' -- ip to bind on
	port: 9001 -- port to listen to for web interface
	tls: { -- see tls settings below
	}
  auth: {
    password: {
      "username": "sha256hashOfPassword"
    }
    ldap: {
      host: 'ldaphost' -- ldap host to connect to
      port: 389 -- ldap port to connect to, 389 for tls, 636 for ssl
      method: 'tls' -- method of connection, tls or ssl
      binddn: "OU=Users,DC=example,DC=com" -- search path to find users
      filter: "(&(objectClass=organizationalPerson)(uid=%s))" -- filter path to find user
      domain: 'example' -- domain to prepend to ldap login
    }
  }
}

default['mercury']['loadbalancer']['pools'] = {
	'poolname' => { -- name of the pool/vip
		listener: {
			ip: ""  -- ip of the vip
			port: 0  -- port of the vip
			mode: "(udp|tcp|http|https)" -- what protocol to listen to
			tls: { -- see mercury src/tlsconfig/tls.go for all available options, not supplying this will use defaults
				minversion: 'VersionTLS12', -- minimum version of TLS to allow
  				ciphersuites: %w(TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384), -- ciphersuite to allow
  				curvepreferences: %w(CurveP521) -- curve preference to use
			}
            readtimeout: 0 -- time to wait for http request from client (0 = unlimited, 10 = default)
            writetimeout: 0 -- time to wait for server reply towards client (0 = unlimited, 0 = default)
            ocspstapling: true|false -- enables ocsp stapling (true = default)
		},
  		outboundacls: [
    		{
				action: '(add|remove|replace)', -- what to do with header
				header_key: 'Location', -- header key to do action with
				header_value: 'https://###REQ_HOST######REQ_PATH###'  -- header value to set - not required on remove
			},
    		{
				action: '(add|remove|replace)', -- what to do with cookie
  				cookie_key: 'stky', -- cookie key to do action with
				cookie_value: '###NODE_ID###', -- calculated variable or string
				cookie_expire: '24h', -- time for cookie (ex. 1m, 3s, 24h)
				cookie_secure: true, -- secure
				cookie_httponly: true -- httponly
			},
		],
  		inboundacls: [
    		-- see outboundacls, but actions can also include allow/deny on inbound acls
    		{
				action: '(allow|deny)', -- what to do with cidr
				cidrs: ["127.0.0.1/8", "10.0.0.0/8"] -- network cidrs to apply action to
            },
    		{
				action: '(add|remove|replace)', -- what to do with header
				header_key: 'Location', -- header key to do action with
				header_value: 'https://###REQ_HOST######REQ_PATH###'  -- header value to set - not required on remove
            },
    		{
				action: '(allow|deny)', -- what to do with header (regex are allowed to allow/deny rules)
				header_key: 'User-Agent', -- header key to do action with
                header_value: ".*Macintash.*" -- value regex match for allow/denies are allowed
			},
		],
        errorpage: {
            file: "/var/mercury/sorry.html" -- specifying a sorry page, enables showing this on errors
            trigger_threshold: 500 -- http result code when to show sorry page (e.g. 500 will show the sorrypage on all errors of 500+)
        },
		healthchecks: [{ // >= mercury version 0.10 - allows an array of healthchecks on a Pool
			type: '(httpget|httppost|tcpconnect|icmpping|udpping|tcpping)',
            ip: '1.2.3.4',
            pingpackets: 4,
            pingtimeout: 1
		}],
	    backends: {
			'backendname' => {
				inboundacls: [] -- see earlier inbound acls
				outboundacls: [] -- see earlier inbound acls
				hostnames: [""] -- hostnames to repply on with this backend
				dnsentry: {
					hostname: "www" -- hostname to give dns record for
					domain: "domain.org" -- domain where this host subsides
					ip: "" -- IPv4 of the vip to supply on dns record (will use listener ip above if this is not specified
					ip6: "" -- IPv6 of the vip to supply on dns record (will use listener ip above if this is not specified
				},
				healthcheck: { // <= mercury version 0.9.x - allows only a single healthcheck
					type: '(httpget|httppost|tcpconnect)',
					httpstatus: 200,
					httpheaders: ['Content-Type: application/soap+xml; charset=utf-8'],
					postdata: '<your post body>',
					request: "http://www.domain.org/",
					tls: {
						insecureskipverify: true
					}
				},
                healthcheckmode: "(any|all)" -- default: "all" - should 1 or all checks be ok for backend to be online
				healthchecks: [{ // >= mercury version 0.10 - allows an array of healthchecks
					type: '(httpget|httppost|tcpconnect)',
					httpstatus: 200,
					httpheaders: ['Content-Type: application/soap+xml; charset=utf-8'],
					postdata: '<your post body>',
					request: "http://www.domain.org/",
					tls: {
						insecureskipverify: true
					}
				}],
				balance: {
					method: 'topology,leastconnected' -- see loadbalancing methods for more details
					local_topology: "site" -- see networks below
					preference: 0123 -- priority for preference based loadbalancing (lower has higher preference)
                    active_passive: "(yes|no)" -- default: no - affects monitoring: to only alert if 0 or >1 nodes are online
                    clusternodes: int -- default: #cluster_nodes - affects monitoring: usefull for vips that only live on 1 cluster node
				}
				nodes: [
					{
						search: "recipe:chef_recipe", -- let chef find the remote nodes based on search
						port: 80 -- connect to port 80 of this node
					},
					{
						host: '1.2.3.4' -- specify host/ip
						port: 80 -- connect to port 80 of this node
					}
				],
				connectmode: "(udp|tcp|http|https)", -- what protocol to connect to the backend with
			}
		}

	}
}

default['mercury']['loadbalancer']['networks'] = { -- used for topology loadbalancing
	'site' => {
		cidrs = [ "127.0.0.1/32" ]
	}
}

default['mercury']['dns']['domains']['domain.org'] = { -- local dns records, also uses TTL as default for loadbalanced records
	'ttl' => 10, -- default ttl for all records
	'soa' => { -- standard soa record
  		name: 'mydomain.org',
  		ns: "ns.mydomain.org",
  		email: "hostmaster.mydomain.org",
  		refresh: 30, # time that a slave will refresh from master
  		retry: 30, # retry time if slave failed to connect to master
  		expire: 3600, # cache on slave
  		minimum: 10, # minimum cache time for slave
	},
	'records' => [		-- records that are not loadbalanced but local
		{			
			name: ""	-- for domain records no name needed
			target: "10 mymx.domain.org" -- mx server to send to
			type: "MX"	 -- MX record type
		},
		{
			name: "www2" -- hostname in domain record
			target: "::1" -- target
			type: "AAAA" -- ipv6 record
		}
	]
}

default['mercury']['dns']['allow_forwarding'] = [ "10.10.0.177/32", "::1/128" ] -- allows recursive dns queries for given clients (used when setting mercury as dns forwarding server)
```

### Loadbalancing Methods

* leastconnected - based on current clients connected

* leasttraffic -- based on traffic generated

* preference -- based on preference set in node of backend

* responsetime -- based on responsetime of a backend node (first byte response? or http roundtrip?)

* random -- rng

* roundrobin -- try to switch them a bit

* sticky -- based on the 'stky' cooky which contains the node, requires the following 2 acls:

    ```json
{ action: 'replace', cookie_key: 'stky', cookie_value: '###NODE_ID###', cookie_expire: '24h', cookie_secure: true, cookie_httponly: true, cookie_path: '/' },
{ action: 'add', cookie_key: 'stky', cookie_value: '###NODE_ID###', cookie_expire: '24h', cookie_secure: true, cookie_httponly: true, cookie_path: '/' },
    ```

      note that for stickyness in combination with global loadbalancing, you need to ```add each node to all loadbalancers```. so that the lb can always forward the client to its previous node

* topology -- based on topology network set, requires the network to be set

* firstavailable -- used for compatibility reasons, this ensures that we always return only the first record, and prevents multiple hosts in dns responses.

#### Loadbalancing Performance
When selecting multiple loadbalance options, keep in mind the speed of each of them.
See below a benchmark of the speeds.
```
$ go test -bench=.

  BenchmarkBalancerLeastConnected-4     10000000           160 ns/op
  BenchmarkBalancerLeastTraffic-4       10000000           167 ns/op
  BenchmarkBalancerPreference-4         10000000           163 ns/op
  BenchmarkBalancerRandom-4               200000          9643 ns/op
  BenchmarkBalancerRoundRobin-4          5000000           165 ns/op
  BenchmarkBalancerSticky-4             10000000           124 ns/op
  BenchmarkBalancerTopology-4            2000000           837 ns/op
  BenchmarkBalancerResponseTime-4       10000000           136 ns/op
```

### TLS Settings

TLS settings should be set on the Mercury Cluster and Webservices. But they can be set on Listeners and Backend.
Setting TLS settings only on backends and not on a listener means that SNI will be used to identify a site for the given SSL certificate.

tls: {
    minversion: minimal tls version to allow
  	ciphersuites: cipersuites to allo
  	curvepreferences: curve preference to use
	insecureskipverify: allow a client to connect to insecure SSL certificate (hostname mismatches)

    certificatefile: certificate crt file to use - this should be a path to a file
    certificatekey: certificate key file to use - this should be a path to a file
    databagname: name of the databag to find the SSL certificate
    databagitem: item name of the databag to find the SSL certificate

}

#### TLS Min version
The minimum TLS version to allow.

Options:
* VersionSSL30,
* VersionTLS10,
* VersionTLS11,
* VersionTLS12,

#### TLS Cypher suites
The allowed Cypers, see https://golang.org/pkg/crypto/tls/#pkg-constants for details

Options:
* TLS_RSA_WITH_RC4_128_SHA
* TLS_RSA_WITH_3DES_EDE_CBC_SHA
* TLS_RSA_WITH_AES_128_CBC_SHA
* TLS_RSA_WITH_AES_256_CBC_SHA
* TLS_RSA_WITH_AES_128_CBC_SHA256
* TLS_RSA_WITH_AES_128_GCM_SHA256
* TLS_RSA_WITH_AES_256_GCM_SHA384
* TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
* TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
* TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
* TLS_ECDHE_RSA_WITH_RC4_128_SHA
* TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
* TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
* TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
* TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
* TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
* TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
* TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
* TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
* TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
* TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
* TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
* TLS_FALLBACK_SCSV

#### TLS Recommended Cyphers and HTTP/2:

* TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 <- has to be first if you want HTTP/2 support!

The 4 cipers below are need for the best SSL-Labs certificate but do not support HTTP/2, the HTTP/2 one will slightly downgrade your score
* TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
* TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
* TLS_RSA_WITH_AES_256_GCM_SHA384
* TLS_RSA_WITH_AES_256_CBC_SHA

#### TLS Curve preferences
The tls curve preferences, see https://golang.org/pkg/crypto/tls/#pkg-constants for details

Options:
* CurveP256
* CurveP384
* CurveP521
* X25519

### SSL Certificates
You can use databags to load the certificate, or let them be generated.

#### Automaticly generated certificates
If you supply only the file names on where to find the certificates, the cookbook will generate these certificates and used them in Mercury
Example:
```
tls: {
    certificatefile: "my_certificate.crt"
    certificatekey: "my_certificate.key"
}
```

This wil generate the certificates in the OS default's SSL certificate path, and genrate certificates with the name my_certificate.crt + my_certificate.key


#### Databag controlled certificates
If you supply a databagname, the cookbook will search the databag for the keys provided as file name in the databagitem
Example:
```
tls: {
    databagname: 'mercury'
    databagitem: 'certifactes_production'
    certificatefile: "my_certificate_file"
    certificatekey: "my_certificate_key"
}
```

This will get the certificate from the data bag called 'mercury' with the item 'certificates_production', and search for the keys 'my_certificate_file' and 'my_certificate_key'
The data bag will look something like this:
```
$ knife data bag show mercury certificates_aroductionp --secret-file secrey_key  -Fj

{
  "id": "certificates_production",
   "my_certificate_file": "-----BEGIN CERTIFICATE-----\nMII...\n..aNZ\n-----END CERTIFICATE-----"
}
```


### Examples

Below You can find some example configurations

#### HTTPS VIP example
Simple site, that serves a website using SSL offloading - we allow SSL connects, and use HTTP connects to the backend
```
default['mercury']['loadbalancer']['pools']['my_backend_https'] = {
  listener: { ip: 'myapp_vip', port: 443, mode: 'https' },
  backends: {
    'myapp_backend' => {
      hostnames: ["myapp.mydomain.org"],
      dnsentry: { hostname: 'myapp', domain: 'mydomain.org' },
      healthcheck: { type: 'httpget', httpstatus: 200, request: "http://myapp.mydomain.org/" },
      balance: { method: 'sticky,roundrobin' },
      nodes: [{ search: "recipe:myapp.mydomain.org AND chef_environment:#{node.chef_environment}", port: 80 }],
      connectmode: 'http'
    }
  }
}
```

This will accept connections on 'myapp_vip', which will do a chef search for the nodes serving this application

#### HTTP -> HTTPS redirect example
all requests on this ip on port 80 are redirected to their original domain and path to https://
```
default['mercury']['loadbalancer']['pools']['http_redirect'] = {
  listener: { ip: matrix_ip['backend'], port: 80, mode: 'http' },
  outboundacls: [
    { action: 'add', header_key: 'Location', header_value: 'https://###REQ_HOST######REQ_PATH###' },
    { action: 'add', status_code: 301 }
  ],
  backends: {
    'redirect' => {
      hostnames: ['default'],
      connectmode: 'internal'
    }
  }
}
```

#### HTTP redirect only as default to main website
only requests to myapp.mydomain.org are served, all other requests are redirected to https://myapp.mydomain.org
also we only allow private networks to connect to this site
```
default['mercury']['loadbalancer']['pools']['my_backend_https'] = {
  listener: { ip: 'myapp_vip', port: 443, mode: 'https' },
  backends: {
    'myapp_backend' => {
      hostnames: ["myapp.mydomain.org"],
      dnsentry: { hostname: 'myapp', domain: 'mydomain.org' },
      healthcheck: { type: 'httpget', httpstatus: 200, request: "http://myapp.mydomain.org/" },
      balance: { method: 'sticky,roundrobin' },
      nodes: [{ search: "recipe:myapp.mydomain.org AND chef_environment:#{node.chef_environment}", port: 80 }],
      connectmode: 'http'
    },
    'redirect' => {
      outboundacls: [
        { action: 'add', header_key: 'Location', header_value: 'https://myapp.mydomain.org' },
        { action: 'add', status_code: 301 }
      ],
      inboundacls: [
        { action: 'allow', cidrs: ["127.0.0.1/8", "10.0.0.0/8"] }
      ],
      hostnames: ['default'],
      connectmode: 'internal'
    }
  }
}
```

#### HTTP serve site on all domains
all requests to this ip/port serve this website
```
default['mercury']['loadbalancer']['pools']['my_backend_https'] = {
  listener: { ip: 'myapp_vip', port: 443, mode: 'https' },
  backends: {
    'myapp_backend' => {
      hostnames: ["default"],
      dnsentry: { hostname: 'myapp', domain: 'mydomain.org' },
      healthcheck: { type: 'httpget', httpstatus: 200, request: "http://myapp.mydomain.org/" },
      balance: { method: 'sticky,roundrobin' },
      nodes: [{ search: "recipe:myapp.mydomain.org AND chef_environment:#{node.chef_environment}", port: 80 }],
      connectmode: 'http'
    }
  }
}
```

## Reload and Config updates

A reload should be enough to apply config changes. but some changes will affect clients.

Only when changing the Listener variables of a config, or the TLS config of backends, requires the proxy part of the laodbalancer for this specific Pool to be reloaded.
As such, when changing the IP, port, Connection mode or TLS config, clients currently connected to this pool will be disconnected, and can reconnect once the pool is up again. (mater of miliseconds)

All other configuration items are changable without interruption to the client.

## Error/Sorrypage handling

When a error page is set in the config, it will always show on internal errors (no backend available, or acl allow/deny)
For errors given by a webserver you can use the `trigger_threshold` which will only trigger errors if the status code is equal or higher.

If you do not want the sorry page to show on return codes from the webserver, then set this to a higher number then the http error codes (e.g. 600 or up)

## ACLS

ACL's can be set to add/replace/modify headers, or to allow/deny requests based on headers/cidr (see examples above)
to use ALLOW/DENY, you must use the `INBOUND` acl. you cannot mix allow and deny ACL's together, this will result in only the allow beeing processed.

## License & Authors

- Author:: Ronald Doorn ([rdoorn@schubergphilis.com](mailto:rdoorn@schubergphilis.com))

```text
Copyright:: Schuberg Philis

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
