vcl 4.1;

backend rails {
  .host = "rails:80";
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

sub vcl_hash {
  hash_data(req.http.X-Forwarded-Proto);
}
