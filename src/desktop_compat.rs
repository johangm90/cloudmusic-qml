// Desktop-only QML context properties (`units`, `i18n`) replacing what the real
// Lomiri.Components toolkit injects on Ubuntu Touch. Only compiled with `--features desktop`.
//
// These are set as QQmlContext root context properties (via QmlEngine::set_object_property),
// not QML types/singletons, because dozens of independent .qml files reference `units`/`i18n`
// unqualified (lowercase) with no local declaration -- exactly like the real SDK does it.

use cpp::cpp;
use gettextrs::{gettext, ngettext};
use qmetaobject::*;

cpp! {{
    #include <QtQml/QQmlEngine>
    #include <QtQml/QQmlContext>
}}

#[derive(QObject, Default)]
pub struct Units {
    base: qt_base_class!(trait QObject),
    gu: qt_method!(
        fn gu(&self, n: f64) -> f64 {
            n * 8.0
        }
    ),
    dp: qt_method!(
        fn dp(&self, n: f64) -> f64 {
            n
        }
    ),
}

// QML calls this both as `i18n.tr(singular)` and `i18n.tr(singular, plural, n)`. A single
// qmetaobject-rs invokable is fixed-arity (calling it from QML with the wrong argument count
// fails with "Insufficient arguments", it does not pad missing trailing args like some other
// Qt call paths do), so the two call shapes are exposed as two differently-named methods
// here, and `i18n` itself -- the object every app .qml file actually calls -- is a tiny
// dynamically-instantiated QML QtObject (see `make_i18n_wrapper` below) with a real variadic
// JS `tr(a, b, c)` function that dispatches to whichever of these fits.
#[derive(QObject, Default)]
pub struct I18nBackend {
    base: qt_base_class!(trait QObject),
    tr: qt_method!(
        fn tr(&self, msgid: QString) -> QString {
            gettext(msgid.to_string()).into()
        }
    ),
    #[allow(non_snake_case)]
    trPlural: qt_method!(
        fn trPlural(&self, singular: QString, plural: QString, n: i32) -> QString {
            ngettext(singular.to_string(), plural.to_string(), n.max(0) as u32).into()
        }
    ),
}

const I18N_WRAPPER_QML: &str = "import QtQuick 2.7\nQtObject {\n    function tr(a, b, c) {\n        if (c === undefined) {\n            return i18nBackend.tr(a)\n        }\n        return i18nBackend.trPlural(a, b, c)\n    }\n}\n";

/// Instantiates the tiny QML shim above and returns its raw QObject*, ready to be set as
/// the "i18n" root context property. `i18nBackend` must already be set as a context
/// property on `engine` before this object's `tr()` is ever called (not before this
/// function runs -- the QML function body is evaluated lazily on each call).
pub fn make_i18n_wrapper(engine: &QmlEngine) -> *mut std::ffi::c_void {
    let mut component = QmlComponent::new(engine);
    component.set_data(QByteArray::from(I18N_WRAPPER_QML));
    let obj_ptr = component.create();
    if obj_ptr.is_null() {
        panic!("failed to create desktop i18n QML wrapper (compat/i18n)");
    }
    // Leak the component itself (not the created object) so the QQmlComponent stays alive
    // for the process lifetime; QQmlComponent only owns the *factory*, not objects it created.
    std::mem::forget(component);
    obj_ptr
}

pub fn set_context_property_object(engine: &QmlEngine, name: &str, obj_ptr: *mut std::ffi::c_void) {
    let engine_ptr = engine.cpp_ptr();
    let name = QString::from(name);
    cpp!(unsafe [engine_ptr as "QQmlEngine *", name as "QString", obj_ptr as "QObject *"] {
        engine_ptr->rootContext()->setContextProperty(name, obj_ptr);
    });
}
