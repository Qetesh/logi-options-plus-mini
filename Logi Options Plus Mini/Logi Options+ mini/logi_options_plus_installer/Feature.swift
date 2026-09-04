import Foundation

enum Feature: String, CaseIterable {
    case quiet = "quiet"
    case analytics = "analytics"
    case flow = "flow"
    case sso = "sso"
    case update = "update"
    case dfu = "dfu"
    case backlight = "backlight"
    case logivoice = "logivoice"
    case aipromptbuilder = "aipromptbuilder"
    case deviceRecommendation = "device-recommendation"
    case smartactions = "smartactions"
    case actionsRing = "actions-ring"
    case installAdobePlugins = "install-adobe-plugins"
    
    var description: String {
        switch self {
        case .quiet: return "Quiet Install"
        case .analytics: return "Analytics"
        case .flow: return "Flow"
        case .sso: return "SSO"
        case .update: return "Update"
        case .dfu: return "DFU"
        case .backlight: return "Backlight"
        case .logivoice: return "LogiVoice"
        case .aipromptbuilder: return "AI Prompt Builder"
        case .deviceRecommendation: return "Device Recommendation"
        case .smartactions: return "Smart Actions"
        case .actionsRing: return "Actions Ring"
        case .installAdobePlugins: return "Adobe Plugins"
        }
    }
    
    var help: String {
        switch self {
        case .quiet: return String(localized: "Installs the app silently without the UI.")
        case .analytics: return String(localized: "Shows or hides choice for users to opt in to share app usage and diagnostics data. Default value is Yes.")
        case .flow: return String(localized: "Shows or hides the Flow feature. Default value is Yes.")
        case .sso: return String(localized: "Shows or hides ability for users to sign into the app. Default value is Yes.")
        case .update: return String(localized: "Enables or disables app updates. Default value is Yes.")
        case .dfu: return String(localized: "Enables or disables device firmware updates. Default value is Yes.")
        case .backlight: return String(localized: "Enables or disables keyboard backlight on the supported keyboards. Default value is Yes.")
        case .logivoice: return String(localized: "Enables or disables LogiVoice feature. Default value is Yes.")
        case .aipromptbuilder: return String(localized: "Enables or disables AI Prompt Builder feature. Default value is Yes.")
        case .deviceRecommendation: return String(localized: "Enables or disables device recommendation feature. Default value is Yes.")
        case .smartactions: return String(localized: "Enables or disables Smart Actions feature. Default value is Yes.")
        case .actionsRing: return String(localized: "Enables or disables Actions Ring feature. Default value is Yes.")
        case .installAdobePlugins: return String(localized: "Installs all Adobe plugins (Lightroom, Illustrator, Photoshop and Premiere Pro).")
        }
    }
}
