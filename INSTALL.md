# Installing My Effect

**After Effects 2023 or newer**, on **Windows x64** or **macOS 11 or newer**
(universal — Apple Silicon and Intel). Pick your platform:

- [Windows](#windows) — one file, no extra steps.
- [macOS](#macos) — one bundle, plus one Terminal command.

> This file ships inside the release ZIP. Edit it for your plugin — the
> placeholders below are already named after you if you used `new-plugin.sh`.

## Windows

### Install

1. Quit After Effects. AE loads plugins once at launch and holds them open, so
   copying over a running install either fails or does nothing.
2. Extract the ZIP.
3. Copy **`MyEffect.aex`** into your After Effects plug-ins folder:

   ```
   C:\Program Files\Adobe\Adobe After Effects <version>\Support Files\Plug-ins\Effects\
   ```

   If After Effects is installed somewhere other than `C:\Program Files`, use
   that install's `Support Files\Plug-ins\Effects` folder instead. This location
   is usually writable without administrator rights.

   There is also a shared folder at
   `C:\Program Files\Adobe\Common\Plug-ins\7.0\MediaCore\`. It works, but
   Premiere Pro and Media Encoder probe it on every launch for an effect only
   After Effects can use, so prefer the AE-specific folder above.

4. Start After Effects. The effect appears under **Effect > Acme > My Effect**.

That is the whole install. One file, no installer, nothing written to the
registry. To uninstall, delete `MyEffect.aex` and restart AE.

### Verifying the download

Each release publishes a SHA-256 for the ZIP. To check yours:

```powershell
Get-FileHash MyEffect-v1.0.0-win-x64.zip -Algorithm SHA256
```

Compare it to the hash on the release page. This matters more than usual here,
because the plugin is not code-signed (see below).

### If it does not show up

**Check the AE version.** 2023 or newer. Older hosts use a different plugin
registration mechanism this build does not implement, and will ignore the file
silently rather than report an error.

**Check you copied it to an `Effects` folder** that belongs to the AE you
actually launched. Several Adobe versions installed side by side each have their
own, and a plugin in the wrong one simply never loads.

**Check Windows did not block the file.** Right-click `MyEffect.aex` >
Properties. If there is an "Unblock" checkbox at the bottom, tick it and click
OK, then restart AE.

**Check your antivirus.** This build is not code-signed, and some AV products
quarantine unsigned DLLs on sight, usually without telling you. If the file
disappears from the plug-ins folder after you copy it, that is what happened;
add an exclusion for the plug-ins folder or restore it from quarantine.

### A note on code signing

This build is **not code-signed**. Windows does not block it, because
`MyEffect.aex` is a library loaded by After Effects rather than a program you
run — SmartScreen's reputation check applies to executables launched from
Explorer, which this never is. That is why the plugin ships as a plain ZIP
instead of an installer.

## macOS

### Install

1. Quit After Effects. AE loads plugins once at launch, so a plugin added while
   it is running is not picked up.
2. Double-click the ZIP to extract it.
3. Move **`MyEffect.plugin`** into After Effects' own plug-ins folder:

   ```
   /Applications/Adobe After Effects <version>/Plug-ins/
   ```

   Substitute your version, e.g. `Adobe After Effects 2026`. Move the whole
   `MyEffect.plugin` — the Finder shows it as a single item, but it is a folder
   and only works intact. This folder belongs to you, so the Finder will not ask
   for an administrator password.

4. **Clear the download flag.** Open Terminal and run:

   ```bash
   xattr -dr com.apple.quarantine "/Applications/Adobe After Effects <version>/Plug-ins/MyEffect.plugin"
   ```

   Rather than typing the path, you can type `xattr -dr com.apple.quarantine `
   (with a trailing space), drag `MyEffect.plugin` from the Finder onto the
   Terminal window, and press Return.

   **Without this step the plugin will not load.** macOS flags everything
   downloaded from the internet, and because this plugin is not notarized by
   Apple, that flag makes macOS refuse to load it. You may see a warning that
   Apple could not verify it is free of malware, or the effect may simply never
   appear — After Effects is given no way to tell you why.

5. Start After Effects. The effect appears under **Effect > Acme > My Effect**.

To uninstall, delete `MyEffect.plugin` and restart AE. **Repeat step 4 after
every update** — each new download carries a fresh flag.

### Verifying the download

Each release publishes a SHA-256 for the ZIP. In Terminal:

```bash
shasum -a 256 ~/Downloads/MyEffect-v1.0.0-macos-universal.zip
```

Compare it to the hash on the release page. Do this before step 4: clearing the
download flag is you telling macOS to trust the file, so first make sure it is
the file you think it is.

### If it does not show up

**Re-check step 4.** This is by far the most common cause. If macOS showed a
warning about unverified software, clear the flag, then quit and restart After
Effects.

**Check the AE version.** 2023 or newer, as on Windows.

**Check the bundle is whole and in the right place.** This file must exist:

```
/Applications/Adobe After Effects <version>/Plug-ins/MyEffect.plugin/Contents/MacOS/MyEffect
```

Several Adobe versions installed side by side each have their own `Plug-ins`
folder, and a plugin in the wrong one simply never loads.

**Quit After Effects completely** (After Effects > Quit After Effects, or ⌘Q)
before starting it again. Closing the window leaves it running.

**Collect a diagnostic log** if none of that helps. Quit After Effects, then
start it from Terminal with logging switched on:

```bash
open --env MYEFFECT_DIAG=1 -a "Adobe After Effects <version>"
```

Reproduce the problem on a single frame, quit After Effects, then run
`open "$TMPDIR"` to show `myeffect.log` in the Finder. Attach it to your bug
report.

### A note on notarization

The macOS build is signed, but **not notarized** by Apple. Notarization requires
a paid Apple Developer account; this build skips it, and step 4 is the cost. The
`xattr` command tells macOS you trust this one plugin. It changes nothing else
on your Mac.

Managed or corporate Macs may not allow the step at all. If yours does not, this
build cannot be installed on it.
