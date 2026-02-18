vcl 4.1;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .first_byte_timeout = 600s;
    .connect_timeout = 5s;
    .between_bytes_timeout = 60s;
}


acl purge {
    "localhost";
    "127.0.0.1";
    "::1";
    "162.243.188.66";
    "134.209.223.131";
    "2604:a880:400:d1:0:1:c89:a001";
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}

sub vcl_recv {

    # Add this right at the start
    if (req.http.X-Forwarded-Proto == "https") {
        set req.http.X-Forwarded-Port = "443";
    } else {
        set req.http.X-Forwarded-Port = "80";
    }


    if (req.method == "PURGE") {
        if (client.ip ~ purge) {
            return (purge);
        }
        return (synth(405, "Not allowed."));
    }

    # -------------------------------------------------
    # STATIC + MEDIA CACHE (ignore cookies)
    # -------------------------------------------------
    if (req.url ~ "\.(jpg|jpeg|png|gif|webp|avif|svg|ico|css|js|woff2|woff|ttf|mp3|ogg|mp4|webm|weba)$") {
        unset req.http.cookie;
    }

    set req.grace = 30s;

    # -------------------------------------------------
    # TUS UPLOAD BYPASS (resumable uploads)
    # -------------------------------------------------
    # Handle Starmus 4-way transport heading to /files/
    if (req.url ~ "^/files/" || 
        req.http.Tus-Resumable || 
        req.http.Transfer-Encoding ~ "chunked" || 
        req.method == "PATCH") {
    
        # PIPE is mandatory for 64-bit chunks and TUS streams
        # It prevents Varnish from timing out on large offsets
        return (pipe);
    }

    # Standard XHR/AJAX can still use pass
    if (req.http.X-Requested-With == "XMLHttpRequest") {
        return (pass);
    }

    # -------------------------------------------------
    # STARMUS RECORDER / REALTIME BYPASS
    # -------------------------------------------------
    if (req.method == "POST" && req.url ~ "/wp-json/star-starmus-audio-recorder/") {
        return (pass);
    }

    if (req.url ~ "^/wp-json/starmus/" || req.url ~ "^/star-starmus/") {
        return (pass);
    }

    # -------------------------------------------------
    # GRAPHQL HANDLING
    # Cache GET queries, bypass POST mutations
    # -------------------------------------------------
    if (req.url ~ "^/graphql") {
        if (req.method == "POST") {
            return (pass);
        }
        unset req.http.cookie;
        return (hash);
    }

    # WordPress plugin/theme activation bypass
    if (req.method == "POST" && req.url ~ "plugins.php") {
        return (pass);
    }

    # -------------------------------------------------
    # DYNAMIC / AUTH / ADMIN BYPASS
    # -------------------------------------------------
    if (req.method == "POST" ||
        req.http.Authorization ||
        req.http.cookie ~ "wordpress_logged_in_" ||
        req.http.cookie ~ "woocommerce_items_in_cart" ||
        req.url ~ "^/(wp-login|wp-admin|wp-cron|wp-json|ignite|cart|checkout|my-account|lost-password)" ||
        req.url ~ "preview=true" ||
        req.url ~ "^/star-") {
        return (pass);
    }

    if (req.url ~ "^/(phpmyadmin|phppgadmin|server-status).*") {
        return (synth(403, "Access denied"));
    }

    # -------------------------------------------------
    # CLEAN COOKIES
    # -------------------------------------------------
    if (req.http.cookie) {
        set req.http.cookie = regsuball(req.http.cookie,
            "(^|;\s*)(has_js|__utm[a-z]+|_ga|_gid|G_AUTHUSER_H|wp-settings-\d+|wp-settings-time-\d+)=[^;]*;?\s*", "\1");
        set req.http.cookie = regsuball(req.http.cookie, "; +$", "");
        if (req.http.cookie == "") {
            unset req.http.cookie;
        }
    }

    # -------------------------------------------------
    # NORMALIZE ENCODING
    # -------------------------------------------------
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "br") {
            set req.http.Accept-Encoding = "br";
        } elseif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    return (hash);
}

sub vcl_backend_response {

    set beresp.grace = 1h;

    if (beresp.http.Set-Cookie || beresp.status >= 400) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # HTML short cache
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 120s;
    }
    # MEDIA long cache (recordings, video, audio)
    elsif (beresp.http.Content-Type ~ "image|audio|video") {
        set beresp.ttl = 30d;
    }
    # JS/CSS long cache (fix heavy JS bundles)
    elsif (beresp.http.Content-Type ~ "css|javascript") {
        set beresp.ttl = 30d;
        set beresp.http.Cache-Control = "public, max-age=2592000";
    }
    else {
        set beresp.ttl = 5m;
    }

    unset beresp.http.X-Powered-By;
    unset beresp.http.Server;

    return (deliver);
}

sub vcl_deliver {

    unset resp.http.X-Powered-By;

    if (obj.hits > 0) {
        set resp.http.X-Varnish-Cache = "HIT";
    } else {
        set resp.http.X-Varnish-Cache = "MISS";
    }

    set resp.http.X-Varnish = resp.http.X-Varnish + " (hits: " + obj.hits + ")";
}

sub vcl_purge {
    ban("req.http.host == " + req.http.host + " && req.url == " + req.url);
    return (synth(200, "Purged successfully."));
}
