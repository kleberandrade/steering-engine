import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _getItem(JSString key);
@JS('localStorage.setItem')
external void _setItem(JSString key, JSString value);
@JS('document.documentElement.lang')
external set _documentLanguage(JSString value);
@JS('window.open')
external JSObject? _open(JSString url, JSString target, JSString features);
String? loadLanguage() {
  try {
    final language = _getItem('steering-language'.toJS)?.toDart;
    _documentLanguage = (language == 'pt' ? 'pt-BR' : 'en').toJS;
    return language;
  } catch (_) {
    return null;
  }
}

void saveLanguage(String language) {
  try {
    _documentLanguage = (language == 'pt' ? 'pt-BR' : 'en').toJS;
    _setItem('steering-language'.toJS, language.toJS);
  } catch (_) {
    /* Storage may be disabled. */
  }
}

bool openDocumentation(String url) {
  _open(url.toJS, '_blank'.toJS, 'noopener,noreferrer'.toJS);
  return true;
}
