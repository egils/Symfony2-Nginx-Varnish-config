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

	if (!beresp.cacheable) {
		return (pass);
	}

	if (beresp.http.Set-Cookie) {
		return (pass);
	}

	return (deliver);
}

sub vcl_miss {
    if (req.request == "PURGE") {
        error 404 "Not purged";
    }
}

sub vcl_hit {
    if (req.request == "PURGE") {
        set obj.ttl = 0s;
        error 200 "Purged";
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
