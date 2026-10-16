#pragma once

#include <windows.h>

namespace ws::integrity {

// Whether Luma itself runs elevated (asked once). Elevated, it starts what
// the user opens with the user's normal rights through Explorer; not
// elevated, it starts them itself.
bool processElevated();

// Whether `window` belongs to a process of higher integrity than Luma's (an
// elevated program while Luma is not). Windows (UIPI) then drops the keys
// Luma would send it (SendInput reports nothing), refuses its messages and
// AttachThreadInput, and while it is in front Luma's hooks and Raw Input
// see no keys. Not asked when Luma is elevated itself: false. A process
// that cannot be asked counts as higher (GitHub #21, docs/pitfalls.md).
bool higherThanOurs(HWND window);

} // namespace ws::integrity
