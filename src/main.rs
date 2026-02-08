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

mod qrc;

#[derive(QObject, Default)]
struct FileManager {
    base: qt_base_class!(trait QObject),
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
}

fn main() {
    init_gettext();
    unsafe {
        cpp! { {
            #include <QtCore/QCoreApplication>
            #include <QtCore/QString>
        }}
        cpp! {[]{
            QCoreApplication::setApplicationName(QStringLiteral("cloudmusic.jgm90.com"));
        }}
    }
    QQuickStyle::set_style("Suru");
    qrc::load();
    qml_register_type::<FileManager>(cstr!("FileManager"), 1, 0, cstr!("FileManager"));

    let mut engine = QmlEngine::new();
    engine.load_file("qrc:/qml/Main.qml".into());
    engine.exec();
}

fn init_gettext() {
    let domain = "cloudmusic.jgm90.com";
    textdomain(domain).expect("Failed to set gettext domain");

    let mut app_dir_path = env::current_dir().expect("Failed to get the app working directory");
    if !app_dir_path.is_absolute() {
        app_dir_path = PathBuf::from("/usr");
    }

    let path = app_dir_path.join("share/locale");

    bindtextdomain(domain, path.to_str().unwrap()).expect("Failed to bind gettext domain");
}
