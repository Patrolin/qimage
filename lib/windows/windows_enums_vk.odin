package lib_windows
import coreWin "core:sys/windows"

/*
// https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
reservedCounter = autoCounter = 0;
a = $0.innerText.split("\n").map(v => {
    const [name, value, comment] = v.split("\t").map(w => w.trim());
    let m;
    if ((name || '-') !== '-') {
        const coreName = `coreWin.${name}`;
        return `${name} :: ${coreName} // ${comment}`;
    } else if (['Reserved', 'Unassigned', 'OEM specific', 'Undefined'].includes(comment)) {
        return `//RESERVED_${reservedCounter++} :: // ${value}`;
    } else if (m = comment.match(/(\d) key/)) {
        return `VK_NUM${m[1]} :: ${value} // ${comment}`;
    } else if (m = comment.match(/([A-Z]) key/)) {
        return `VK_KEY${m[1]} :: ${value} // ${comment}`;
    } else {
        return `AUTO_${autoCounter++} :: ${value} // ${comment}`;
    }
}).slice(1).join('\n')
console.log(a);
*/
VK_LBUTTON :: coreWin.VK_LBUTTON // Left mouse button
VK_RBUTTON :: coreWin.VK_RBUTTON // Right mouse button
VK_CANCEL :: coreWin.VK_CANCEL // Control-break processing
VK_MBUTTON :: coreWin.VK_MBUTTON // Middle mouse button
VK_XBUTTON1 :: coreWin.VK_XBUTTON1 // X1 mouse button
VK_XBUTTON2 :: coreWin.VK_XBUTTON2 // X2 mouse button
//RESERVED_0 :: // 0x07
VK_BACK :: coreWin.VK_BACK // BACKSPACE key
VK_TAB :: coreWin.VK_TAB // TAB key
//RESERVED_1 :: // 0x0A-0B
VK_CLEAR :: coreWin.VK_CLEAR // CLEAR key
VK_RETURN :: coreWin.VK_RETURN // ENTER key
//RESERVED_2 :: // 0x0E-0F
VK_SHIFT :: coreWin.VK_SHIFT // SHIFT key
VK_CONTROL :: coreWin.VK_CONTROL // CTRL key
VK_MENU :: coreWin.VK_MENU // ALT key
VK_PAUSE :: coreWin.VK_PAUSE // PAUSE key
VK_CAPITAL :: coreWin.VK_CAPITAL // CAPS LOCK key
VK_KANA :: coreWin.VK_KANA // IME Kana mode
VK_HANGUL :: coreWin.VK_HANGUL // IME Hangul mode
VK_IME_ON :: coreWin.VK_IME_ON // IME On
VK_JUNJA :: coreWin.VK_JUNJA // IME Junja mode
VK_FINAL :: coreWin.VK_FINAL // IME final mode
VK_HANJA :: coreWin.VK_HANJA // IME Hanja mode
VK_KANJI :: coreWin.VK_KANJI // IME Kanji mode
VK_IME_OFF :: coreWin.VK_IME_OFF // IME Off
VK_ESCAPE :: coreWin.VK_ESCAPE // ESC key
VK_CONVERT :: coreWin.VK_CONVERT // IME convert
VK_NONCONVERT :: coreWin.VK_NONCONVERT // IME nonconvert
VK_ACCEPT :: coreWin.VK_ACCEPT // IME accept
VK_MODECHANGE :: coreWin.VK_MODECHANGE // IME mode change request
VK_SPACE :: coreWin.VK_SPACE // SPACEBAR
VK_PRIOR :: coreWin.VK_PRIOR // PAGE UP key
VK_NEXT :: coreWin.VK_NEXT // PAGE DOWN key
VK_END :: coreWin.VK_END // END key
VK_HOME :: coreWin.VK_HOME // HOME key
VK_LEFT :: coreWin.VK_LEFT // LEFT ARROW key
VK_UP :: coreWin.VK_UP // UP ARROW key
VK_RIGHT :: coreWin.VK_RIGHT // RIGHT ARROW key
VK_DOWN :: coreWin.VK_DOWN // DOWN ARROW key
VK_SELECT :: coreWin.VK_SELECT // SELECT key
VK_PRINT :: coreWin.VK_PRINT // PRINT key
VK_EXECUTE :: coreWin.VK_EXECUTE // EXECUTE key
VK_SNAPSHOT :: coreWin.VK_SNAPSHOT // PRINT SCREEN key
VK_INSERT :: coreWin.VK_INSERT // INS key
VK_DELETE :: coreWin.VK_DELETE // DEL key
VK_HELP :: coreWin.VK_HELP // HELP key
VK_NUM0 :: 0x30 // 0 key
VK_NUM1 :: 0x31 // 1 key
VK_NUM2 :: 0x32 // 2 key
VK_NUM3 :: 0x33 // 3 key
VK_NUM4 :: 0x34 // 4 key
VK_NUM5 :: 0x35 // 5 key
VK_NUM6 :: 0x36 // 6 key
VK_NUM7 :: 0x37 // 7 key
VK_NUM8 :: 0x38 // 8 key
VK_NUM9 :: 0x39 // 9 key
//RESERVED_3 :: // 0x3A-40
VK_KEYA :: 0x41 // A key
VK_KEYB :: 0x42 // B key
VK_KEYC :: 0x43 // C key
VK_KEYD :: 0x44 // D key
VK_KEYE :: 0x45 // E key
VK_KEYF :: 0x46 // F key
VK_KEYG :: 0x47 // G key
VK_KEYH :: 0x48 // H key
VK_KEYI :: 0x49 // I key
VK_KEYJ :: 0x4A // J key
VK_KEYK :: 0x4B // K key
VK_KEYL :: 0x4C // L key
VK_KEYM :: 0x4D // M key
VK_KEYN :: 0x4E // N key
VK_KEYO :: 0x4F // O key
VK_KEYP :: 0x50 // P key
VK_KEYQ :: 0x51 // Q key
VK_KEYR :: 0x52 // R key
VK_KEYS :: 0x53 // S key
VK_KEYT :: 0x54 // T key
VK_KEYU :: 0x55 // U key
VK_KEYV :: 0x56 // V key
VK_KEYW :: 0x57 // W key
VK_KEYX :: 0x58 // X key
VK_KEYY :: 0x59 // Y key
VK_KEYZ :: 0x5A // Z key
VK_LWIN :: coreWin.VK_LWIN // Left Windows key
VK_RWIN :: coreWin.VK_RWIN // Right Windows key
VK_APPS :: coreWin.VK_APPS // Applications key
//RESERVED_4 :: // 0x5E
VK_SLEEP :: coreWin.VK_SLEEP // Computer Sleep key
VK_NUMPAD0 :: coreWin.VK_NUMPAD0 // Numeric keypad 0 key
VK_NUMPAD1 :: coreWin.VK_NUMPAD1 // Numeric keypad 1 key
VK_NUMPAD2 :: coreWin.VK_NUMPAD2 // Numeric keypad 2 key
VK_NUMPAD3 :: coreWin.VK_NUMPAD3 // Numeric keypad 3 key
VK_NUMPAD4 :: coreWin.VK_NUMPAD4 // Numeric keypad 4 key
VK_NUMPAD5 :: coreWin.VK_NUMPAD5 // Numeric keypad 5 key
VK_NUMPAD6 :: coreWin.VK_NUMPAD6 // Numeric keypad 6 key
VK_NUMPAD7 :: coreWin.VK_NUMPAD7 // Numeric keypad 7 key
VK_NUMPAD8 :: coreWin.VK_NUMPAD8 // Numeric keypad 8 key
VK_NUMPAD9 :: coreWin.VK_NUMPAD9 // Numeric keypad 9 key
VK_MULTIPLY :: coreWin.VK_MULTIPLY // Multiply key
VK_ADD :: coreWin.VK_ADD // Add key
VK_SEPARATOR :: coreWin.VK_SEPARATOR // Separator key
VK_SUBTRACT :: coreWin.VK_SUBTRACT // Subtract key
VK_DECIMAL :: coreWin.VK_DECIMAL // Decimal key
VK_DIVIDE :: coreWin.VK_DIVIDE // Divide key
VK_F1 :: coreWin.VK_F1 // F1 key
VK_F2 :: coreWin.VK_F2 // F2 key
VK_F3 :: coreWin.VK_F3 // F3 key
VK_F4 :: coreWin.VK_F4 // F4 key
VK_F5 :: coreWin.VK_F5 // F5 key
VK_F6 :: coreWin.VK_F6 // F6 key
VK_F7 :: coreWin.VK_F7 // F7 key
VK_F8 :: coreWin.VK_F8 // F8 key
VK_F9 :: coreWin.VK_F9 // F9 key
VK_F10 :: coreWin.VK_F10 // F10 key
VK_F11 :: coreWin.VK_F11 // F11 key
VK_F12 :: coreWin.VK_F12 // F12 key
VK_F13 :: coreWin.VK_F13 // F13 key
VK_F14 :: coreWin.VK_F14 // F14 key
VK_F15 :: coreWin.VK_F15 // F15 key
VK_F16 :: coreWin.VK_F16 // F16 key
VK_F17 :: coreWin.VK_F17 // F17 key
VK_F18 :: coreWin.VK_F18 // F18 key
VK_F19 :: coreWin.VK_F19 // F19 key
VK_F20 :: coreWin.VK_F20 // F20 key
VK_F21 :: coreWin.VK_F21 // F21 key
VK_F22 :: coreWin.VK_F22 // F22 key
VK_F23 :: coreWin.VK_F23 // F23 key
VK_F24 :: coreWin.VK_F24 // F24 key
//RESERVED_5 :: // 0x88-8F
VK_NUMLOCK :: coreWin.VK_NUMLOCK // NUM LOCK key
VK_SCROLL :: coreWin.VK_SCROLL // SCROLL LOCK key
//RESERVED_6 :: // 0x92-96
//RESERVED_7 :: // 0x97-9F
VK_LSHIFT :: coreWin.VK_LSHIFT // Left SHIFT key
VK_RSHIFT :: coreWin.VK_RSHIFT // Right SHIFT key
VK_LCONTROL :: coreWin.VK_LCONTROL // Left CONTROL key
VK_RCONTROL :: coreWin.VK_RCONTROL // Right CONTROL key
VK_LMENU :: coreWin.VK_LMENU // Left ALT key
VK_RMENU :: coreWin.VK_RMENU // Right ALT key
VK_BROWSER_BACK :: coreWin.VK_BROWSER_BACK // Browser Back key
VK_BROWSER_FORWARD :: coreWin.VK_BROWSER_FORWARD // Browser Forward key
VK_BROWSER_REFRESH :: coreWin.VK_BROWSER_REFRESH // Browser Refresh key
VK_BROWSER_STOP :: coreWin.VK_BROWSER_STOP // Browser Stop key
VK_BROWSER_SEARCH :: coreWin.VK_BROWSER_SEARCH // Browser Search key
VK_BROWSER_FAVORITES :: coreWin.VK_BROWSER_FAVORITES // Browser Favorites key
VK_BROWSER_HOME :: coreWin.VK_BROWSER_HOME // Browser Start and Home key
VK_VOLUME_MUTE :: coreWin.VK_VOLUME_MUTE // Volume Mute key
VK_VOLUME_DOWN :: coreWin.VK_VOLUME_DOWN // Volume Down key
VK_VOLUME_UP :: coreWin.VK_VOLUME_UP // Volume Up key
VK_MEDIA_NEXT_TRACK :: coreWin.VK_MEDIA_NEXT_TRACK // Next Track key
VK_MEDIA_PREV_TRACK :: coreWin.VK_MEDIA_PREV_TRACK // Previous Track key
VK_MEDIA_STOP :: coreWin.VK_MEDIA_STOP // Stop Media key
VK_MEDIA_PLAY_PAUSE :: coreWin.VK_MEDIA_PLAY_PAUSE // Play/Pause Media key
VK_LAUNCH_MAIL :: coreWin.VK_LAUNCH_MAIL // Start Mail key
VK_LAUNCH_MEDIA_SELECT :: coreWin.VK_LAUNCH_MEDIA_SELECT // Select Media key
VK_LAUNCH_APP1 :: coreWin.VK_LAUNCH_APP1 // Start Application 1 key
VK_LAUNCH_APP2 :: coreWin.VK_LAUNCH_APP2 // Start Application 2 key
//RESERVED_8 :: // 0xB8-B9
VK_OEM_1 :: coreWin.VK_OEM_1 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ;: key
VK_OEM_PLUS :: coreWin.VK_OEM_PLUS // For any country/region, the + key
VK_OEM_COMMA :: coreWin.VK_OEM_COMMA // For any country/region, the , key
VK_OEM_MINUS :: coreWin.VK_OEM_MINUS // For any country/region, the - key
VK_OEM_PERIOD :: coreWin.VK_OEM_PERIOD // For any country/region, the . key
VK_OEM_2 :: coreWin.VK_OEM_2 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the /? key
VK_OEM_3 :: coreWin.VK_OEM_3 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the `~ key
//RESERVED_9 :: // 0xC1-DA
VK_OEM_4 :: coreWin.VK_OEM_4 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the [{ key
VK_OEM_5 :: coreWin.VK_OEM_5 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the \\| key
VK_OEM_6 :: coreWin.VK_OEM_6 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the ]} key
VK_OEM_7 :: coreWin.VK_OEM_7 // Used for miscellaneous characters; it can vary by keyboard. For the US standard keyboard, the '" key
VK_OEM_8 :: coreWin.VK_OEM_8 // Used for miscellaneous characters; it can vary by keyboard.
//RESERVED_10 :: // 0xE0
//RESERVED_11 :: // 0xE1
VK_OEM_102 :: coreWin.VK_OEM_102 // The <> keys on the US standard keyboard, or the \\| key on the non-US 102-key keyboard
//RESERVED_12 :: // 0xE3-E4
VK_PROCESSKEY :: coreWin.VK_PROCESSKEY // IME PROCESS key
//RESERVED_13 :: // 0xE6
VK_PACKET :: coreWin.VK_PACKET // Used to pass Unicode characters as if they were keystrokes. The VK_PACKET key is the low word of a 32-bit Virtual Key value used for non-keyboard input methods. For more information, see Remark in KEYBDINPUT, SendInput, WM_KEYDOWN, and WM_KEYUP
//RESERVED_14 :: // 0xE8
//RESERVED_15 :: // 0xE9-F5
VK_ATTN :: coreWin.VK_ATTN // Attn key
VK_CRSEL :: coreWin.VK_CRSEL // CrSel key
VK_EXSEL :: coreWin.VK_EXSEL // ExSel key
VK_EREOF :: coreWin.VK_EREOF // Erase EOF key
VK_PLAY :: coreWin.VK_PLAY // Play key
VK_ZOOM :: coreWin.VK_ZOOM // Zoom key
VK_NONAME :: coreWin.VK_NONAME // Reserved
VK_PA1 :: coreWin.VK_PA1 // PA1 key
VK_OEM_CLEAR :: coreWin.VK_OEM_CLEAR // Clear key
