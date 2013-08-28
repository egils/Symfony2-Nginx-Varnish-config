##
## Set info to access backend nginx server
backend default {
    	.host = "127.0.0.1";
    	.port = "80";  ## Use 8080 if not in DEV environment.
}

##
## Cache only content with no cookies
sub vcl_recv {
    	unset req.http.cookie;
}
sub vcl_fetch {
    	unset beresp.http.set-cookie;
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
