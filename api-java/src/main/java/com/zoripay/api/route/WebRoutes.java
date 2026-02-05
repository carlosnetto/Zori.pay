package com.zoripay.api.route;

import io.javalin.http.Context;

public class WebRoutes {

    public void index(Context ctx) {
        ctx.html("<h1>Zori.pay API Server (Java)</h1>"
                + "<p>Use the <a href=\"https://zoripay.xyz\">web frontend</a> to access Zori.</p>");
    }

    public void oauthCallback(Context ctx) {
        ctx.redirect("/");
    }

    public void health(Context ctx) {
        ctx.result("OK");
    }
}
