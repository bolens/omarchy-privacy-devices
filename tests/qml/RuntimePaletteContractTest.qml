pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Commons as Commons

// Isolated process only: exercise the real supported Commons singleton API.
ShellRoot {
    id: test
    readonly property var inventory: {
    "Style.spacing": {
        "scale": "real",
        "hairline": "int",
        "xxs": "int",
        "xs": "int",
        "sm": "int",
        "md": "int",
        "lg": "int",
        "xl": "int",
        "xxl": "int",
        "xxxl": "int",
        "huge": "int",
        "controlGap": "int",
        "controlPaddingX": "int",
        "controlPaddingY": "int",
        "inputPaddingY": "int",
        "controlHeight": "int",
        "popupRowHeight": "int",
        "dropdownWidth": "int",
        "searchableDropdownWidth": "int",
        "numberFieldWidth": "int",
        "searchablePopupMinHeight": "int",
        "rowGap": "int",
        "rowPaddingX": "int",
        "labelGap": "int",
        "panelGap": "int",
        "panelPadding": "int",
        "popupPadding": "int",
        "objectName": "string"
    },
    "Style.font": {
        "family": "string",
        "resolvedFamily": "string",
        "menuFamily": "string",
        "baseSize": "int",
        "caption": "int",
        "bodySmall": "int",
        "body": "int",
        "subtitle": "int",
        "title": "int",
        "heading": "int",
        "display": "int",
        "displayLarge": "int",
        "iconSmall": "int",
        "icon": "int",
        "iconLarge": "int",
        "objectName": "string"
    },
    "Style.bar": {
        "sizeHorizontal": "int",
        "sizeVertical": "int",
        "iconSlot": "int",
        "iconCanvas": "int",
        "iconFont": "int",
        "statusSlot": "int",
        "objectName": "string"
    },
    "Color.bar": {
        "background": "color",
        "text": "color",
        "active": "color",
        "objectName": "string"
    },
    "Color.popups": {
        "background": "color",
        "text": "color",
        "border": "color",
        "objectName": "string"
    },
    "Color.tooltip": {
        "background": "color",
        "text": "color",
        "border": "color",
        "objectName": "string"
    },
    "Color.notifications": {
        "background": "color",
        "text": "color",
        "border": "color",
        "countdown": "color",
        "objectName": "string"
    },
    "Color.menu": {
        "background": "color",
        "text": "color",
        "border": "color",
        "scrim": "color",
        "selectedBackground": "color",
        "selectedText": "color",
        "selectedBorder": "color",
        "objectName": "string"
    },
    "Color.polkit": {
        "background": "color",
        "text": "color",
        "textError": "color",
        "border": "color",
        "borderError": "color",
        "accent": "color",
        "scrim": "color",
        "objectName": "string"
    },
    "Color.lock": {
        "background": "color",
        "text": "color",
        "placeholder": "color",
        "textError": "color",
        "border": "color",
        "borderActive": "color",
        "borderError": "color",
        "selection": "color",
        "objectName": "string"
    },
    "Color.imagePicker": {
        "scrim": "color",
        "text": "color",
        "selectedBorder": "color",
        "unselectedBorder": "color",
        "objectName": "string"
    }
}
    property var originalObjects: ({})
    property var originalFields: ({})
    property var saved: null
    property var desired: null
    property int phase: 0
    property bool finished: false

    function groups() {
        return {
            "Style.spacing": Commons.Style.spacing, "Style.font": Commons.Style.font,
            "Style.bar": Commons.Style.bar, "Color.bar": Commons.Color.bar,
            "Color.popups": Commons.Color.popups, "Color.tooltip": Commons.Color.tooltip,
            "Color.notifications": Commons.Color.notifications, "Color.menu": Commons.Color.menu,
            "Color.polkit": Commons.Color.polkit, "Color.lock": Commons.Color.lock,
            "Color.imagePicker": Commons.Color.imagePicker
        }
    }
    function assertThat(condition, message) {
        if (!condition) throw new Error("Palette contract: " + message)
    }
    function merged(original, changes) {
        const result = Object.assign({}, original)
        for (const key of Object.keys(changes)) result[key] = changes[key]
        return result
    }
    function fields() {
        const current = test.groups()
        const result = {}
        let count = 0
        test.assertThat(Object.keys(current).length === 11, "object count")
        for (const name of Object.keys(test.inventory)) {
            const object = current[name]
            test.assertThat(object !== null && typeof object === "object", name + " missing")
            const expected = test.inventory[name]
            // Include the eleven inherited QObject.objectName string fields.
            const actual = Object.keys(object).filter(function(key) {
                return typeof object[key] !== "function"
            }).sort()
            test.assertThat(JSON.stringify(actual) === JSON.stringify(Object.keys(expected).sort()), name + " field inventory")
            result[name] = {}
            for (const key of Object.keys(expected)) {
                const kind = expected[key]
                const value = object[key]
                if (kind === "int" || kind === "real") {
                    test.assertThat(typeof value === "number" && isFinite(value), name + "." + key + " numeric type")
                    if (kind === "int") test.assertThat(Number.isInteger(value), name + "." + key + " integer type")
                } else {
                    test.assertThat(typeof value === (kind === "color" ? "object" : "string"), name + "." + key + " declared type")
                }
                result[name][key] = kind === "color" ? String(value) : value
                count += 1
            }
        }
        test.assertThat(count === 98, "field census")
        return result
    }
    function identities() {
        const current = test.groups()
        for (const name of Object.keys(test.inventory))
            test.assertThat(current[name] === test.originalObjects[name], name + " identity changed")
    }
    function readonlyOwners() {
        for (const name of Object.keys(test.inventory)) {
            const parts = name.split(".")
            const owner = parts[0] === "Style" ? Commons.Style : Commons.Color
            let rejected = false
            try { owner[parts[1]] = null } catch (error) { rejected = true }
            test.assertThat(rejected, name + " owner replacement accepted")
        }
        test.identities()
    }
    function textGroups() {
        return ["bar", "popups", "tooltip", "notifications", "menu", "polkit", "lock", "imagePicker"]
    }
    function textKey(name) {
        return (name === "imagePicker" ? "image-picker" : name) + ".text"
    }
    function textsEqual(value) {
        for (const name of test.textGroups())
            if (String(Commons.Color[name].text) !== value) return false
        return true
    }
    function restoreTextBindings() {
        for (const name of test.textGroups()) {
            const key = test.textKey(name)
            // Exact original named Color token text expression, including fallback.
            Commons.Color[name].text = Qt.binding(function() {
                return Commons.Color.pick(key, Commons.Color.foreground)
            })
        }
    }
    function restoreInputs() {
        Commons.Style.fontBaseSize = test.saved.fontBaseSize
        Commons.Style.fontOverrides = test.saved.fontOverrides
        Commons.Style.spacingOverrides = test.saved.spacingOverrides
        Commons.Style.barOverrides = test.saved.barOverrides
        Commons.Color.foreground = test.saved.foreground
        Commons.Color.shellValues = test.saved.shellValues
    }
    function schedule() {
        Qt.callLater(test.advance)
    }
    function startupReady() {
        return Commons.Color.colorsFile.loaded && Commons.Color.shellFile.loaded
            && Commons.Color.userShellFile.loaded
            && typeof Commons.Style.resolvedFontFamily === "string"
            && Commons.Style.resolvedFontFamily.trim().length > 0
    }
    function advance() {
        if (test.finished) return
        if (test.phase === 0) {
            // Owned fixtures create all three files. Wait until their real
            // asynchronous vendor onLoaded/mergeShell handlers have completed.
            if (!test.startupReady()) return
            test.originalObjects = test.groups()
            test.originalFields = test.fields()
            test.readonlyOwners()
            test.saved = {
                fontBaseSize: Commons.Style.fontBaseSize, fontOverrides: Commons.Style.fontOverrides,
                spacingOverrides: Commons.Style.spacingOverrides, barOverrides: Commons.Style.barOverrides,
                foreground: String(Commons.Color.foreground), shellValues: Commons.Color.shellValues
            }
            test.desired = {
                base: Commons.Style.fontBaseSize + 3, caption: Commons.Style.font.caption + 7,
                body: Commons.Style.font.body + 9, md: Commons.Style.spacing.md + 11,
                bar: Commons.Style.bar.sizeHorizontal + 13,
                color: String(Commons.Color.foreground) === "#13579b" ? "#2468ac" : "#13579b"
            }
            const colors = Object.assign({}, test.saved.shellValues)
            for (const name of test.textGroups()) delete colors[test.textKey(name)]
            test.phase = 1
            Commons.Style.fontBaseSize = test.desired.base
            Commons.Style.fontOverrides = test.merged(test.saved.fontOverrides, {caption: test.desired.caption, body: test.desired.body})
            Commons.Style.spacingOverrides = test.merged(test.saved.spacingOverrides, {md: test.desired.md})
            Commons.Style.barOverrides = test.merged(test.saved.barOverrides, {"size-horizontal": test.desired.bar})
            Commons.Color.shellValues = colors
            Commons.Color.foreground = test.desired.color
            test.schedule()
        } else if (test.phase === 1) {
            const bar = Math.max(1, Math.round(test.desired.bar * (Commons.Style.barScaleWithFont ? Commons.Style.fontScale : 1)))
            if (Commons.Style.font.baseSize !== test.desired.base || Commons.Style.font.caption !== test.desired.caption
                    || Commons.Style.font.body !== test.desired.body || Commons.Style.spacing.md !== test.desired.md
                    || Commons.Style.bar.sizeHorizontal !== bar || !test.textsEqual(test.desired.color)) return
            test.fields()
            test.identities()
            // Child properties remain writable although all eleven owners are readonly.
            for (const name of test.textGroups()) Commons.Color[name].text = "#abcdef"
            test.assertThat(test.textsEqual("#abcdef"), "mutable Color children rejected")
            test.restoreTextBindings()
            test.phase = 2
            test.schedule()
        } else if (test.phase === 2) {
            // Prove restoration reinstated live bindings, not just snapshot values.
            if (!test.textsEqual(test.desired.color)) return
            test.phase = 3
            test.restoreInputs()
            test.schedule()
        } else if (test.phase === 3) {
            if (JSON.stringify(test.fields()) !== JSON.stringify(test.originalFields)) return
            test.identities()
            test.assertThat(Commons.Style.fontBaseSize === test.saved.fontBaseSize
                && Commons.Style.fontOverrides === test.saved.fontOverrides
                && Commons.Style.spacingOverrides === test.saved.spacingOverrides
                && Commons.Style.barOverrides === test.saved.barOverrides
                && String(Commons.Color.foreground) === String(test.saved.foreground)
                && Commons.Color.shellValues === test.saved.shellValues, "original inputs not restored")
            test.finished = true
            console.log("PALETTE_QML_CONTRACT_OK")
            Qt.quit()
        }
    }
    Component.onCompleted: test.schedule()
    Connections {
        target: Commons.Style
        function onResolvedFontFamilyChanged() { test.schedule() }
        function onFontBaseSizeChanged() { test.schedule() }
        function onFontOverridesChanged() { test.schedule() }
        function onSpacingOverridesChanged() { test.schedule() }
        function onBarOverridesChanged() { test.schedule() }
    }
    Connections {
        target: Commons.Color
        function onForegroundChanged() { test.schedule() }
        function onShellValuesChanged() { test.schedule() }
    }
    Connections {
        target: Commons.Color.colorsFile
        function onLoaded() { test.schedule() }
        function onLoadFailed() { test.schedule() }
    }
    Connections {
        target: Commons.Color.shellFile
        function onLoaded() { test.schedule() }
        function onLoadFailed() { test.schedule() }
    }
    Connections {
        target: Commons.Color.userShellFile
        function onLoaded() { test.schedule() }
        function onLoadFailed() { test.schedule() }
    }
    Timer {
        interval: 4000
        running: !test.finished
        repeat: false
        onTriggered: {
            throw new Error("Palette contract readiness deadline at phase " + test.phase
                + "; fixture files loaded=" + Commons.Color.colorsFile.loaded
                + "," + Commons.Color.shellFile.loaded + "," + Commons.Color.userShellFile.loaded
                + "; font ready=" + (Commons.Style.resolvedFontFamily.trim().length > 0))
        }
    }
}
