# ViewBridge Error Messages in Agent Sessions

## Overview
When running Agent Sessions, you may see error messages in the debug console related to ViewBridge and RemoteViewService. These are **benign system messages** that do not indicate any issues with the application.

## Common Error Messages

### ViewBridge to RemoteViewService Terminated
```
Error Domain=com.apple.ViewBridge Code=18 "(null)" 
UserInfo={com.apple.ViewBridge.error.hint=this process disconnected remote view controller -- benign unless unexpected, 
com.apple.ViewBridge.error.description=NSViewBridgeErrorCanceled}
```

### Unable to open mach-O / Metal Library Errors
```
Unable to open mach-O at path: default.metallib  Error:2
fopen failed for data file: errno = 2 (No such file or directory)
Errors found! Invalidating cache
```

## Why These Messages Appear

### ViewBridge Messages
These messages occur when macOS system UI components temporarily connect and disconnect from remote view services. This is **normal behavior** when the app:

1. **Opens file/folder pickers** - The `NSOpenPanel` in FirstRunPrompt for selecting the Codex CLI sessions directory
2. **Shows preferences window** - The PreferencesWindowController uses NSHostingController to display SwiftUI views
3. **Uses any system UI components** - Color pickers, font panels, or other system-provided UI elements

### Metal Library Messages
The Metal library errors occur because:
- SwiftUI apps on macOS may attempt to load Metal shaders for rendering optimizations
- The app doesn't include custom Metal shaders (default.metallib)
- The system falls back to standard rendering when Metal libraries aren't found
- These errors are **completely harmless** for apps that don't use custom Metal shaders

## Resolution Applied

To ensure proper file system access for the developer tool:

1. **Created entitlements file** (`AgentSessions.entitlements`) without app sandbox:
   - No sandbox restrictions (developer tool needs full file system access)
   - Allows reading from `~/.codex/sessions` or `CODEX_HOME/sessions`
   - Users can select custom session directories

2. **Updated project settings** to reference the entitlements file in both Debug and Release configurations

## Are These Errors a Problem?

**No.** As Apple's error message itself states: "benign unless unexpected". These messages:
- Do not affect app functionality
- Are expected when using system UI components
- Can be safely ignored during normal operation

## When to Be Concerned

Only investigate further if:
- The app crashes or becomes unresponsive
- File/folder selection stops working
- Preferences window fails to open
- You see these errors continuously in a loop

## Additional Notes

### Common Debug Console Messages
All of these are **benign** and can be safely ignored:
- `ViewBridge to RemoteViewService Terminated` - Normal when system UI disconnects
- `Unable to open mach-O at path: default.metallib` - App doesn't use custom Metal shaders
- `fopen failed for data file` - Related to Metal library lookup
- `Errors found! Invalidating cache` - System clearing Metal shader cache

### App Sandbox Decision
Agent Sessions does **not** use app sandboxing because:
- It's a developer tool that needs to read session files from arbitrary locations
- Users may have `CODEX_HOME` set to various paths
- The app needs flexibility to access different directories based on user configuration
