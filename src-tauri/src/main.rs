#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::time::Duration;

use serde::Serialize;
use tauri::{Emitter, Manager};
use tokio::time::sleep;
use url::Url;

const BACKEND_URL: &str = "http://127.0.0.1:3080/";
const RETRY_INTERVAL: Duration = Duration::from_secs(3);
const RETRY_COUNT: usize = 20;

#[derive(Serialize)]
struct BackendEvent<'a> {
    status: &'a str,
    url: &'a str,
    error: Option<String>,
}

async fn probe_backend() -> Result<(), String> {
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(2))
        .build()
        .map_err(|error| error.to_string())?;

    let response = client
        .get(BACKEND_URL)
        .send()
        .await
        .map_err(|error| error.to_string())?;

    if response.status().is_success() {
        Ok(())
    } else {
        Err(format!("后端返回 HTTP {}", response.status()))
    }
}

#[tauri::command]
async fn check_backend_status() -> Result<String, String> {
    probe_backend().await.map(|()| "connected".to_owned())
}

#[tauri::command]
fn get_backend_url() -> &'static str {
    BACKEND_URL
}

fn navigate(window: &tauri::WebviewWindow, target: &str) {
    let Ok(url) = Url::parse(target) else {
        return;
    };
    let _ = window.navigate(url);
}

fn watch_backend(app: tauri::AppHandle) {
    tauri::async_runtime::spawn(async move {
        let mut last_error = "后端尚未启动".to_owned();

        for _ in 0..RETRY_COUNT {
            match probe_backend().await {
                Ok(()) => {
                    if let Some(window) = app.get_webview_window("main") {
                        navigate(&window, BACKEND_URL);
                    }
                    let _ = app.emit(
                        "backend-ready",
                        BackendEvent { status: "connected", url: BACKEND_URL, error: None },
                    );
                    return;
                }
                Err(error) => last_error = error,
            }
            sleep(RETRY_INTERVAL).await;
        }

        if let Some(window) = app.get_webview_window("main") {
            navigate(&window, "tauri://localhost/unavailable.html");
        }
        let _ = app.emit(
            "backend-unavailable",
            BackendEvent { status: "unavailable", url: BACKEND_URL, error: Some(last_error) },
        );
    });
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![check_backend_status, get_backend_url])
        .setup(|app| {
            watch_backend(app.handle().clone());
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("failed to run DeepSeek Harness Desktop");
}
