// Desktop-only stub for Lomiri.Components' `ViewItems` attached property (drag-to-reorder
// support used once, in PlaylistDetail.qml's song list). qmetaobject-rs's safe
// `qml_register_type` wrapper always registers `attachedPropertiesFunction`/
// `attachedPropertiesMetaObject` as null (see qtdeclarative.rs), so there is no safe way to
// expose an attached property through it. This mirrors that same function's internal
// `QQmlPrivate::RegisterType` call (same struct, same field order) and fills in those two
// fields instead, registering `ViewItems` into the same "Lomiri.Components" URI our other
// compat types live in.
//
// We only need `ViewItems.dragMode` and `ViewItems.onDragUpdated` to *parse* -- the real
// drag gesture has no desktop equivalent here and is never triggered (`dragUpdated` is
// declared but never emitted), so PlaylistDetail.qml loads and plays back normally; only
// the manual long-press drag-to-reorder gesture is a no-op on desktop.

use cpp::cpp;
use cstr::cstr;
use qmetaobject::*;
use std::os::raw::c_void;

cpp! {{
    #include <QtQml/QQmlEngine>
    #include <QtQml/QQmlComponent>
    #include <qqmlprivate.h>
}}

#[derive(QObject, Default)]
pub struct ViewItemsAttached {
    base: qt_base_class!(trait QObject),
    #[allow(non_snake_case)]
    dragMode: qt_property!(bool),
    #[allow(non_snake_case)]
    dragUpdated: qt_signal!(event: QVariant),
}

extern "C" fn create_view_items_attached(requesting_object: *mut c_void) -> *mut c_void {
    let obj_ptr = into_leaked_cpp_ptr(ViewItemsAttached::default());
    cpp!(unsafe [requesting_object as "QObject *", obj_ptr as "QObject *"] {
        if (requesting_object) {
            obj_ptr->setParent(requesting_object);
        }
    });
    obj_ptr
}

pub fn register() {
    let uri = cstr!("Lomiri.Components");
    let qml_name = cstr!("ViewItems");
    let uri_ptr = uri.as_ptr();
    let qml_name_ptr = qml_name.as_ptr();
    let meta_object = ViewItemsAttached::static_meta_object();
    let attached_fn: extern "C" fn(*mut c_void) -> *mut c_void = create_view_items_attached;
    let type_id = <std::cell::RefCell<ViewItemsAttached> as PropertyType>::register_type(
        Default::default(),
    );
    let size = ViewItemsAttached::cpp_size();
    let version_major: u32 = 1;
    let version_minor: u32 = 0;

    cpp!(unsafe [
        qml_name_ptr as "char *",
        uri_ptr as "char *",
        version_major as "int",
        version_minor as "int",
        meta_object as "const QMetaObject *",
        attached_fn as "QQmlAttachedPropertiesFunc",
        size as "size_t",
        type_id as "int"
    ] {
        QQmlPrivate::RegisterType api = {
            /*version*/ 0,

            /*typeId*/ type_id,
            /*listId*/ {},
            /*objectSize*/ int(size),
            /*create*/ nullptr,
            /*noCreationReason*/ QStringLiteral("ViewItems is an attached property only"),

            /*uri*/ uri_ptr,
            /*versionMajor*/ version_major,
            /*versionMinor*/ version_minor,
            /*elementName*/ qml_name_ptr,
            /*metaObject*/ meta_object,

            /*attachedPropertiesFunction*/ attached_fn,
            /*attachedPropertiesMetaObject*/ meta_object,

            /*parserStatusCast*/ -1,
            /*valueSourceCast*/ -1,
            /*valueInterceptorCast*/ -1,

            /*extensionObjectCreate*/ nullptr,
            /*extensionMetaObject*/ nullptr,
            /*customParser*/ nullptr,
            /*revision*/ {}
        };
        QQmlPrivate::qmlregister(QQmlPrivate::TypeRegistration, &api);
    });
}
