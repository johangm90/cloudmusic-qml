/*
 * Copyright (C) 2026  Your FullName
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * appname is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#[macro_use]
extern crate cstr;
#[macro_use]
extern crate qmetaobject;

use std::env;
use std::fs;
use std::path::PathBuf;

use gettextrs::{bindtextdomain, textdomain};
use qmetaobject::*;
use cpp::cpp;
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread;

mod qrc;
mod local_api;

#[derive(QObject, Default)]
struct FileManager {
    base: qt_base_class!(trait QObject),
    #[allow(non_snake_case)]
    changeFileName: qt_method!(
        fn changeFileName(&self, url_file: String, file_dir: String, name_song: String) {
            let src = PathBuf::from(url_file);
            let mut dest = PathBuf::from(file_dir);
            let file_name = format!("{name_song}.mp3");
            dest.push(file_name);
            if let Err(err) = fs::rename(&src, &dest) {
                eprintln!("Failed to rename {:?} -> {:?}: {err}", src, dest);
            }
        }
    ),
    #[allow(non_snake_case)]
    moveFile: qt_method!(
        fn moveFile(&self, source_path: String, new_name: String) -> bool {
            let src = PathBuf::from(&source_path);
            
            // Get the directory from the source path
            if let Some(parent) = src.parent() {
                let mut dest = parent.to_path_buf();
                dest.push(new_name);
                
                match fs::rename(&src, &dest) {
                    Ok(_) => {
                        eprintln!("File renamed successfully: {:?} -> {:?}", src, dest);
                        true
                    }
                    Err(err) => {
                        eprintln!("Failed to rename {:?} -> {:?}: {err}", src, dest);
                        false
                    }
                }
            } else {
                eprintln!("Failed to get parent directory from path: {source_path}");
                false
            }
        }
    ),
}

#[derive(QObject)]
struct CloudMusic {
    base: qt_base_class!(trait QObject),
    requestFinished: qt_signal!(
        request_id: QString,
        ok: bool,
        payload_json: QString,
        error: QString
    ),
    tx: Sender<AsyncResult>,
    rx: Receiver<AsyncResult>,
    call: qt_method!(
        fn call(&self, action: QString, params_json: QString) -> QString {
            local_api::direct_call(&action.to_string(), &params_json.to_string()).into()
        }
    ),
    callAsync: qt_method!(
        fn callAsync(&self, action: QString, params_json: QString, request_id: QString) {
            let tx = self.tx.clone();
            let action_s = action.to_string();
            let params_s = params_json.to_string();
            let request_s = request_id.to_string();
            thread::spawn(move || {
                let raw = local_api::direct_call(&action_s, &params_s);
                let (ok, error) = match serde_json::from_str::<serde_json::Value>(&raw) {
                    Ok(v) => {
                        if let Some(e) = v.get("error").and_then(serde_json::Value::as_str) {
                            (false, e.to_string())
                        } else {
                            (true, String::new())
                        }
                    }
                    Err(e) => (false, format!("invalid json response: {e}")),
                };
                let _ = tx.send(AsyncResult {
                    request_id: request_s,
                    ok,
                    payload_json: raw,
                    error,
                });
            });
        }
    ),
    pumpResponses: qt_method!(
        fn pumpResponses(&self) {
            for _ in 0..64 {
                match self.rx.try_recv() {
                    Ok(result) => {
                        self.requestFinished(
                            result.request_id.into(),
                            result.ok,
                            result.payload_json.into(),
                            result.error.into(),
                        );
                    }
                    Err(_) => break,
                }
            }
        }
    ),
}

struct AsyncResult {
    request_id: String,
    ok: bool,
    payload_json: String,
    error: String,
}

impl Default for CloudMusic {
    fn default() -> Self {
        let (tx, rx) = channel::<AsyncResult>();
        Self {
            base: Default::default(),
            requestFinished: Default::default(),
            tx,
            rx,
            call: Default::default(),
            callAsync: Default::default(),
            pumpResponses: Default::default(),
        }
    }
}

fn main() {
    init_gettext();
    local_api::spawn_local_api_server();
    unsafe {
        cpp! { {
            #include <QtCore/QCoreApplication>
            #include <QtCore/QString>
        }}
        cpp! {[]{
            QCoreApplication::setApplicationName(QStringLiteral("apu.johangm90"));
        }}
    }
    QQuickStyle::set_style("Suru");
    qrc::load();
    qml_register_type::<FileManager>(cstr!("FileManager"), 1, 0, cstr!("FileManager"));
    qml_register_type::<CloudMusic>(cstr!("CloudMusic"), 1, 0, cstr!("CloudMusic"));

    let mut engine = QmlEngine::new();
    engine.load_file("qrc:/qml/Main.qml".into());
    engine.exec();
}

fn init_gettext() {
    let domain = "apu.johangm90";
    textdomain(domain).expect("Failed to set gettext domain");

    let mut app_dir_path = env::current_dir().expect("Failed to get the app working directory");
    if !app_dir_path.is_absolute() {
        app_dir_path = PathBuf::from("/usr");
    }

    let path = app_dir_path.join("share/locale");

    bindtextdomain(domain, path.to_str().unwrap()).expect("Failed to bind gettext domain");
}
