vcl 4.0;

backend rails {
  .host = "rails:3000";
}

backend minio {
  .host = "minio:9000";
}

sub vcl_recv {
  if (req.url ~ "^/uploads/") {
    set req.backend_hint = minio;
  } else {
    set req.backend_hint = rails;
  }
}
