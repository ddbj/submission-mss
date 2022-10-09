vcl 4.1;

backend rails {
  .host = "rails:3000";
}

backend minio {
  .host = "minio:9000";
}

sub vcl_recv {
  if (req.url ~ "^/uploads/") {
    set req.backend_hint = minio;

    return (pipe);
  } else {
    set req.backend_hint = rails;
  }
}

sub vcl_backend_response {
  if (bereq.url ~ "^/(assets|workers)/") {
    set beresp.ttl                = 1d;
    set beresp.http.Cache-Control = "public, max-age=31536000";
  }

  if (beresp.http.Content-Type ~ "^text/(html|css|plain)|application/(javascript|json/(\w+\+)?xml)(\s*;.+)?$") {
    set beresp.do_gzip = true;
  }
}

sub vcl_hash {
  hash_data(req.http.X-Forwarded-Proto);
}
