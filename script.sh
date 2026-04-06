#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-my-project}"

echo "Creating reusable Leptos template at: ${PROJECT_ROOT}"

mkdir -p "${PROJECT_ROOT}"/{public,style,app/src,server/src}

cat > "${PROJECT_ROOT}/Cargo.toml" <<'EOF'
[workspace]
members = ["app", "server"]
resolver = "2"

[workspace.dependencies]
axum = "0.8.8"
console_error_panic_hook = "0.1"
leptos = "0.8.17"
leptos_axum = "0.8.8"
leptos_meta = "0.8.6"
leptos_router = "0.8.13"
serde = { version = "1", features = ["derive"] }
thiserror = "2"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
tower-http = { version = "0.6", features = ["trace"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
wasm-bindgen = "0.2"

[[workspace.metadata.leptos]]
name = "my-project"
bin-package = "server"
lib-package = "app"
output-name = "my-project"
site-root = "target/site"
site-pkg-dir = "pkg"
style-file = "style/main.scss"
assets-dir = "public"
site-addr = "127.0.0.1:3000"
reload-port = 3001
browserquery = "defaults"
env = "DEV"
server-fn-prefix = "/api"
server-fn-mod-path = true
watch-additional-files = ["app/src", "server/src", "style"]
EOF

cat > "${PROJECT_ROOT}/rust-toolchain.toml" <<'EOF'
[toolchain]
channel = "stable"
targets = ["wasm32-unknown-unknown"]
components = ["rustfmt", "clippy"]
EOF

cat > "${PROJECT_ROOT}/.gitignore" <<'EOF'
/target
/.idea
/.vscode
.DS_Store
EOF

cat > "${PROJECT_ROOT}/README.md" <<'EOF'
# my-project

Reusable Leptos SSR starter template with:

- root workspace
- app crate for UI and server functions
- server crate for Axum SSR host
- SCSS support
- one sample route
- one sample server function
EOF

: > "${PROJECT_ROOT}/public/favicon.ico"

cat > "${PROJECT_ROOT}/style/main.scss" <<'EOF'
:root {
  --bg: #0b1220;
  --panel: #111827;
  --panel-2: #1f2937;
  --text: #e5e7eb;
  --muted: #94a3b8;
  --accent: #38bdf8;
  --border: #334155;
  --success: #22c55e;
  --error: #f97316;
}

* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
}

body {
  font-family: Inter, system-ui, sans-serif;
  background: linear-gradient(180deg, #020617 0%, var(--bg) 100%);
  color: var(--text);
}

main {
  width: min(960px, calc(100% - 2rem));
  margin: 0 auto;
  padding: 3rem 0;
}

.card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 1.25rem;
  box-shadow: 0 18px 60px rgba(2, 6, 23, 0.35);
}

p {
  color: var(--muted);
}

label,
input,
button {
  font: inherit;
}

input {
  width: 100%;
  padding: 0.9rem 1rem;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--panel-2);
  color: var(--text);
}

button {
  margin-top: 1rem;
  padding: 0.9rem 1.1rem;
  border: 0;
  border-radius: 12px;
  background: var(--accent);
  color: #082f49;
  font-weight: 700;
  cursor: pointer;
}
EOF

cat > "${PROJECT_ROOT}/app/Cargo.toml" <<'EOF'
[package]
name = "app"
version = "0.1.0"
edition = "2024"

[lib]
crate-type = ["cdylib", "rlib"]

[features]
default = []
hydrate = [
  "leptos/hydrate",
  "leptos_meta/hydrate",
  "leptos_router/hydrate",
]
ssr = [
  "dep:leptos_axum",
  "dep:thiserror",
  "leptos/ssr",
  "leptos_meta/ssr",
  "leptos_router/ssr",
]

[dependencies]
console_error_panic_hook = { workspace = true }
leptos = { workspace = true }
leptos_axum = { workspace = true, optional = true }
leptos_meta = { workspace = true }
leptos_router = { workspace = true }
serde = { workspace = true }
thiserror = { workspace = true, optional = true }
wasm-bindgen = { workspace = true }
EOF

cat > "${PROJECT_ROOT}/app/src/lib.rs" <<'EOF'
use leptos::prelude::*;
use leptos_meta::*;
use leptos_router::components::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct SampleResponse {
    pub message: String,
}

#[server(endpoint = "hello")]
pub async fn hello(name: String) -> Result<SampleResponse, ServerFnError> {
    Ok(SampleResponse {
        message: format!("Hello, {}!", name.trim()),
    })
}

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/my-project.css"/>
        <Title text="my-project"/>

        <Router>
            <Routes fallback=|| view! { <p>"Not found."</p> }>
                <Route path=StaticSegment("") view=HomePage/>
            </Routes>
        </Router>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    let action = ServerAction::<Hello>::new();
    let value = action.value();
    let pending = action.pending();

    view! {
        <main>
            <section class="card">
                <h1>"my-project"</h1>
                <p>"Reusable Leptos starter with one route and one server function."</p>

                <ActionForm action=action>
                    <label for="name">"Your name"</label>
                    <input
                        id="name"
                        type="text"
                        name="name"
                        placeholder="Ada"
                    />
                    <button type="submit">"Send"</button>
                </ActionForm>

                <Show when=move || pending.get()>
                    <p>"Loading…"</p>
                </Show>

                {move || value.get().map(|result| match result {
                    Ok(data) => view! { <p>{data.message}</p> }.into_any(),
                    Err(err) => view! { <p>{format!("Error: {err}")}</p> }.into_any(),
                })}
            </section>
        </main>
    }
}

#[cfg(feature = "hydrate")]
#[wasm_bindgen::prelude::wasm_bindgen]
pub fn hydrate() {
    console_error_panic_hook::set_once();
    leptos::mount::hydrate_body(App);
}
EOF

cat > "${PROJECT_ROOT}/server/Cargo.toml" <<'EOF'
[package]
name = "server"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "server"
path = "src/main.rs"

[dependencies]
app = { path = "../app", features = ["ssr"] }
axum = { workspace = true }
leptos = { workspace = true, features = ["ssr"] }
leptos_axum = { workspace = true }
leptos_meta = { workspace = true, features = ["ssr"] }
leptos_router = { workspace = true, features = ["ssr"] }
tokio = { workspace = true }
tower-http = { workspace = true }
tracing = { workspace = true }
tracing-subscriber = { workspace = true }
EOF

cat > "${PROJECT_ROOT}/server/src/main.rs" <<'EOF'
use app::App;
use axum::Router;
use leptos::config::get_configuration;
use leptos::prelude::*;
use leptos_axum::{generate_route_list, LeptosRoutes};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG")
                .unwrap_or_else(|_| "server=debug,tower_http=debug".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let conf = get_configuration(None).await?;
    let leptos_options = conf.leptos_options;
    let addr = leptos_options.site_addr;
    let routes = generate_route_list(App);

    let app = Router::new()
        .leptos_routes(&leptos_options, routes, || {
            view! { <App/> }
        })
        .layer(TraceLayer::new_for_http())
        .with_state(leptos_options);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    println!("listening on http://{}", addr);
    axum::serve(listener, app).await?;
    Ok(())
}
EOF

echo
echo "Project tree:"
find "${PROJECT_ROOT}" -maxdepth 3 -type f | sort

echo
echo "Next commands:"
cat <<'EOF'
rustup target add wasm32-unknown-unknown
cargo install --locked cargo-leptos

cd my-project
cargo leptos watch
EOF
