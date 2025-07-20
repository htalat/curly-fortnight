# macOS Window Managers

This repository contains two experimental macOS menubar window management applications built with Swift.

## Projects

### win-mgr
A hybrid approach using Core Graphics Window Services API and NSWorkspace for comprehensive window and application management.

**Features:**
- Search box for filtering windows/apps
- Lists all open windows with detailed titles (where available)
- Falls back to application-level switching for apps that don't expose windows
- No special permissions required
- Works with Chrome, Safari, and other modern applications

**Usage:**
```bash
cd win-mgr
swift run
```

### ax-window-mgr
An experimental approach using the Accessibility (AXUIElement) API for detailed window information.

**Features:**
- More detailed window titles from compatible applications
- Cross-space window detection (limited)
- Window state indicators (minimized, other space, etc.)
- Requires Accessibility permissions

**Usage:**
```bash
cd ax-window-mgr
swift run
```

**Note:** Requires granting Accessibility permissions in System Settings → Privacy & Security → Accessibility.

## Comparison

| Feature | win-mgr | ax-window-mgr |
|---------|---------|---------------|
| Chrome/Safari Support | ✅ App-level | ❌ Limited |
| Window Details | ✅ Good | ✅ Excellent (when available) |
| Cross-Space Windows | ❌ No | ⚠️ Limited |
| Permissions Required | ✅ None | ❌ Accessibility |
| Reliability | ✅ High | ⚠️ App-dependent |

## Conclusion

The **win-mgr** hybrid approach provides the most practical solution for general-purpose window management, while **ax-window-mgr** demonstrates the capabilities and limitations of the Accessibility API approach.