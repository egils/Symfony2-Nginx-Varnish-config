##
## Set info to access backend nginx server
backend default {
    	.host = "127.0.0.1";
    	.port = "80";  ## Use 8080 if not in DEV environment.
}

##
## Cache only content with no cookies
sub vcl_recv {
	set req.backend = default;

	## Set headers that ESI cache is supported
    	set req.http.Surrogate-Capability = "abc=ESI/1.0";

	set req.http.X-Forwarded-Port = "8080"; ## Use 80 if not in DEV environment.
	if (req.http.Authorization || req.http.Cookie) {
	    	return (pass);
	}

	## Forward client's ip to backend server.
	if (req.http.x-forwarded-for) {
		set req.http.X-Forwarded-For =
		req.http.X-Forwarded-For ", " client.ip;
	} else {
		set req.http.X-Forwarded-For = client.ip;
	}
}

sub vcl_fetch {

	## Do ESI only if specific header is received.
    	if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        	unset beresp.http.Surrogate-Control;
        	set beresp.do_esi = true;
    	}

	## from http://pastie.org/2094138
	# Varnish determined the object was not cacheable.
	if (req.http.Cookie ~ "(username|sessnion)") {
		set beresp.http.X-Cacheable = "NO:Got Session";
		return(hit_for_pass);
	} elseif (beresp.http.Cache-Control ~ "private") {
		set beresp.http.X-Cacheable = "NO:Cache-Control=private";
		return(hit_for_pass);
	} elseif (beresp.http.Cache-Control ~ "no-cache" || beresp.http.Pragma ~ "no-cache") {
		set beresp.http.X-Cacheable = "Refetch forced by user";
		return(hit_for_pass);
	# You are extending the lifetime of the object artificially
	} elseif (beresp.ttl < 1s) {
		set beresp.ttl   = 5s;
		set beresp.grace = 5s;
		set beresp.http.X-Cacheable = "YES:FORCED";
	# Varnish determined the object was cacheable
	} else {
		set beresp.http.X-Cacheable = "YES";
	}
}

sub vcl_miss {
    	if (req.request == "PURGE") {
        	error 404 "Not purged";
    	}
}

sub vcl_hit {
	  if (req.request == "PURGE") {
	    	purge;
	    	error 200 "Purged.";
	  }
}

##
## Some error reporting for DEV env only.
sub vcl_error {
      	set obj.http.Content-Type = "text/html; charset=utf-8";
      	set obj.http.Retry-After = "5";
      	synthetic {"
  <?xml version="1.0" encoding="utf-8"?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html>
    <head>
      <title>"} + obj.status + " " + obj.response + {"</title>
    </head>
    <body>
      <h1>Error "} + obj.status + " " + obj.response + {"</h1>
      <p>"} + obj.response + {"</p>
      <h3>Guru Meditation:</h3>
      <p>XID: "} + req.xid + {"</p>
      <hr>
      <p>Varnish cache server</p>
    </body>
  </html>
  "};
	return (deliver);
}
