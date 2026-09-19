function build(isDarkTheme, primaryColor) {
    var accent = primaryColor || "#e53446"
    var dark = !!isDarkTheme
    return {
        color: {
            accent: accent,
            page: dark ? "#1f1f1f" : "#f5f5f5",
            card: dark ? "#232323" : "#ffffff",
            border: dark ? "#3a3a3a" : "#d8d8d8",
            section: dark ? "#1a1a1a" : "#ececec",
            text: dark ? "#f2f2f2" : "#1f1f1f",
            textMuted: dark ? "#b8b8b8" : "#666666",
            textInverse: "#ffffff",
            selected: Qt.rgba(0.9, 0.2, 0.28, dark ? 0.22 : 0.16),
            tile: dark ? "#252525" : "#ffffff",
            tileBorder: dark ? "#3a3a3a" : "#dcdcdc",
            overlay: "#55000000",
            toastBg: "#000000",
            toastText: "#ffffff",
            // Elevation/interaction surfaces: one step lighter/darker than `card`
            // so a raised or hovered surface reads as a subtle layer, not a new hue.
            surfaceElevated: dark ? "#2a2a2a" : "#ffffff",
            surfaceHover: dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.035),
            success: dark ? "#4caf6b" : "#2e8b46",
            warning: dark ? "#e0a940" : "#b3791f",
            error: dark ? "#e5605e" : "#c53a37"
        },
        radius: {
            sm: 0.8,
            md: 1.2,
            lg: 2.0
        },
        spacing: {
            // Legacy semantic steps, kept as-is: existing screens read these directly.
            sm: 0.8,
            md: 1.2,
            lg: 1.8,
            page: 1.2,
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
            display: "x-large",
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
