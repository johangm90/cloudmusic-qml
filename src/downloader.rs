// Desktop-only replacement for Lomiri.DownloadManager's SingleDownload. Only compiled
// with `--features desktop`. Registered as a QML-instantiable type ("Downloader"), used by
// the qml/compat shim's SingleDownload.qml.

use cstr::cstr;
use qmetaobject::*;
use std::fs::File;
use std::io::{Read, Write};
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread;

enum DownloadEvent {
    Progress {
        request_id: String,
        received: i64,
        total: i64,
    },
    Finished {
        request_id: String,
        ok: bool,
        path: String,
        error: String,
    },
}

#[derive(QObject)]
pub struct Downloader {
    base: qt_base_class!(trait QObject),
    progress: qt_signal!(request_id: QString, received: i64, total: i64),
    finished: qt_signal!(request_id: QString, ok: bool, path: QString, error: QString),
    tx: Sender<DownloadEvent>,
    rx: Receiver<DownloadEvent>,
    download: qt_method!(
        fn download(&self, url: QString, dest_path: QString, request_id: QString) {
            spawn_download(
                self.tx.clone(),
                url.to_string(),
                dest_path.to_string(),
                request_id.to_string(),
            );
        }
    ),
    // No in-flight requests are ever cancelled by the app today; kept as a harmless no-op
    // so the shim's SingleDownload.qml can still expose a cancel() method.
    cancel: qt_method!(
        fn cancel(&self) {}
    ),
    #[allow(non_snake_case)]
    #[allow(non_snake_case)]
    pumpDownloads: qt_method!(
        fn pumpDownloads(&self) {
            for _ in 0..64 {
                match self.rx.try_recv() {
                    Ok(DownloadEvent::Progress {
                        request_id,
                        received,
                        total,
                    }) => {
                        self.progress(request_id.into(), received, total);
                    }
                    Ok(DownloadEvent::Finished {
                        request_id,
                        ok,
                        path,
                        error,
                    }) => {
                        self.finished(request_id.into(), ok, path.into(), error.into());
                    }
                    Err(_) => break,
                }
            }
        }
    ),
}

impl Default for Downloader {
    fn default() -> Self {
        let (tx, rx) = channel::<DownloadEvent>();
        Self {
            base: Default::default(),
            progress: Default::default(),
            finished: Default::default(),
            tx,
            rx,
            download: Default::default(),
            cancel: Default::default(),
            pumpDownloads: Default::default(),
        }
    }
}

fn spawn_download(tx: Sender<DownloadEvent>, url: String, dest_path: String, request_id: String) {
    thread::spawn(move || {
        let result: Result<String, String> = (|| {
            let client = reqwest::blocking::Client::builder()
                .build()
                .map_err(|e| e.to_string())?;
            let mut resp = client.get(&url).send().map_err(|e| e.to_string())?;
            if !resp.status().is_success() {
                return Err(format!("HTTP {}", resp.status()));
            }
            let total = resp.content_length().unwrap_or(0) as i64;
            let mut file = File::create(&dest_path).map_err(|e| e.to_string())?;
            let mut buf = [0u8; 65536];
            let mut received: i64 = 0;
            loop {
                let n = resp.read(&mut buf).map_err(|e| e.to_string())?;
                if n == 0 {
                    break;
                }
                file.write_all(&buf[..n]).map_err(|e| e.to_string())?;
                received += n as i64;
                let _ = tx.send(DownloadEvent::Progress {
                    request_id: request_id.clone(),
                    received,
                    total,
                });
            }
            Ok(dest_path.clone())
        })();

        match result {
            Ok(path) => {
                let _ = tx.send(DownloadEvent::Finished {
                    request_id,
                    ok: true,
                    path,
                    error: String::new(),
                });
            }
            Err(error) => {
                let _ = tx.send(DownloadEvent::Finished {
                    request_id,
                    ok: false,
                    path: String::new(),
                    error,
                });
            }
        }
    });
}

pub fn register_type() {
    qml_register_type::<Downloader>(cstr!("Downloader"), 1, 0, cstr!("Downloader"));
}
