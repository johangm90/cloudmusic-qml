function build(isDarkTheme, primaryColor) {
    var accent = primaryColor || "#e53446"
    var dark = !!isDarkTheme
    return {
        color: {
            accent: accent,
            page: dark ? "#151516" : "#f7f6f5",
            card: dark ? "#1d1d1f" : "#ffffff",
            border: dark ? "#303034" : "#e5e2df",
            section: dark ? "#111112" : "#efedeb",
            text: dark ? "#f7f5f3" : "#211f1e",
            textMuted: dark ? "#aaa6a4" : "#706b68",
            textInverse: "#ffffff",
            selected: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06),
            tile: dark ? "#202022" : "#ffffff",
            tileBorder: dark ? "#2d2d31" : "#e5e2df",
            overlay: "#55000000",
            toastBg: "#000000",
            toastText: "#ffffff",
            // Elevation/interaction surfaces: one step lighter/darker than `card`
            // so a raised or hovered surface reads as a subtle layer, not a new hue.
            surfaceElevated: dark ? "#28282b" : "#ffffff",
            surfaceHover: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.045),
            success: dark ? "#4caf6b" : "#2e8b46",
            warning: dark ? "#e0a940" : "#b3791f",
            error: dark ? "#e5605e" : "#c53a37"
        },
        radius: {
            sm: 0.6,
            md: 1.0,
            lg: 1.6
        },
        spacing: {
            // Legacy semantic steps, kept as-is: existing screens read these directly.
            sm: 0.8,
            md: 1.2,
            lg: 1.8,
            page: 2.0,
            // 4/8/12/16/24/32/48px scale expressed in grid units (1gu == 8px), for
            // new/refactored components. Prefer this over ad-hoc `spacingX + units.gu(y)` math.
            scale: {
                xs: 0.5,
                sm: 1.0,
                md: 1.5,
                lg: 2.0,
                xl: 3.0,
                xxl: 4.0,
                xxxl: 6.0
            }
        },
        layout: {
            playerToolbarHeight: 7.25,
            // Expanded widths get a persistent player bar with inline transport,
            // seek and volume controls instead of the compact tap-to-expand strip,
            // so it needs more vertical room.
            playerToolbarHeightExpanded: 9.5,
            // Page-width thresholds (gu) for switching between compact/medium/expanded
            // layout structure (columns, rails vs. sidebar, persistent panels, etc).
            // Centralized here so screens stop declaring their own copies.
            breakpoints: {
                medium: 60,
                expanded: 90
            },
            // Target card width (gu) for fluid GridViews (albums/artists grids). Not a
            // layout-mode switch -- it's the size a card tries to stay near as columns
            // are added/removed to fill the available width.
            cardTargetWidth: 25
        },
        typography: {
            display: "xx-large",
            heading: "x-large",
            title: "large",
            body: "medium",
            bodySmall: "small",
            label: "small",
            caption: "x-small"
        }
    }
}

// Classifies an available width (in pixels, already resolved via units.gu()) into
// one of "compact" / "medium" / "expanded" against the shared breakpoints above.
function sizeClassForWidth(widthPx, breakpointMediumPx, breakpointExpandedPx) {
    if (widthPx >= breakpointExpandedPx) {
        return "expanded"
    }
    if (widthPx >= breakpointMediumPx) {
        return "medium"
    }
    return "compact"
}
