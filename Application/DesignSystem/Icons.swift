//
//  Icons.swift
//  GalacticCalendar
//

import Foundation

/// SF Symbol name catalog for Galactic Calendar.
///
/// Views must reference symbols exclusively through these tokens.
enum Icons {

    // MARK: - Navigation

    /// Navigation-related symbols.
    enum Navigation {

        /// Backward navigation.
        static let back = "chevron.left"

        /// Forward navigation.
        static let forward = "chevron.right"

        /// Close / dismiss.
        static let close = "xmark"

        /// Menu affordance.
        static let menu = "line.3.horizontal"
    }

    // MARK: - Calendar

    /// Calendar-related symbols reserved for upcoming calendar UI.
    enum Calendar {

        /// Generic calendar glyph.
        static let calendar = "calendar"

        /// Today affordance.
        static let today = "calendar.circle"

        /// Previous period (month navigation).
        static let previous = "chevron.left"

        /// Next period (month navigation).
        static let next = "chevron.right"

        /// Legacy single-arrow affordance (retained for compatibility).
        static let changeMonth = "chevron.down"

        /// Decorative star paired with the Home calendar control.
        static let star = "sparkle"
    }

    // MARK: - Events

    /// Event-related symbols reserved for the event editor.
    enum Events {

        /// Create event.
        static let add = "plus"

        /// Edit event.
        static let edit = "pencil"

        /// Delete event.
        static let delete = "trash"

        /// Event reminder.
        static let reminder = "bell"

        /// Gift decoration reserved for future day features.
        static let gift = "gift.fill"

        /// Title field glyph.
        static let title = "calendar"

        /// Description field glyph.
        static let description = "doc.text"

        /// Repeat selector glyph.
        static let `repeat` = "arrow.triangle.2.circlepath"

        /// Category / tags selector glyph.
        static let category = "rocket"

        /// Tags multi-select glyph.
        static let tags = "tag.fill"

        /// Priority selector glyph.
        static let priority = "flag.fill"

        /// High-priority upward arrow shown beside the priority value.
        static let priorityUp = "arrow.up"

        /// Chevron affordance for editor selector tiles.
        static let selectorChevron = "chevron.down"

        /// Status selector glyph.
        static let status = "clock"

        /// Event color selector glyph.
        static let color = "paintpalette.fill"

        /// Confirm / save checkmark.
        static let confirm = "checkmark"

        /// Save action sparkles.
        static let save = "sparkles"

        /// Recurrence end affordance.
        static let repeatEnd = "calendar.badge.minus"

        /// Recurrence occurrence-count affordance.
        static let repeatCount = "number"

        /// Duplicate event affordance.
        static let duplicate = "plus.square.on.square"

        /// Move / reprogram event affordance.
        static let move = "arrow.right.circle"

        /// Copy event to another date.
        static let copy = "rectangle.on.rectangle"

        /// Event calendar day selector.
        static let eventDate = "calendar"

        /// All-day event toggle.
        static let allDay = "sun.max"

        /// Event end calendar day selector.
        static let endDate = "calendar.badge.clock"

        /// Event start time selector.
        static let startTime = "clock"

        /// Event end time selector.
        static let endTime = "clock.fill"

        /// Event time zone selector.
        static let timeZone = "globe"

        /// Event template / blueprint affordance.
        static let template = "doc.on.doc"

        /// Save current event as a template.
        static let saveTemplate = "doc.badge.plus"
    }

    // MARK: - Home

    /// Home screen symbols.
    enum Home {

        /// Settings entry.
        static let settings = "gearshape"

        /// Share affordance.
        static let share = "square.and.arrow.up"

        /// Universe message affordance.
        static let universeMessage = "sparkles"

        /// Smart Daily Agenda affordance.
        static let agenda = "list.bullet.rectangle"


        /// Opening quotation mark for Universe Messages.
        static let quote = "quote.opening"

        /// Inspiration badge glyph.
        static let inspiration = "sparkles"
    }

    // MARK: - Universe

    /// Universe Messages module symbols.
    enum Universe {

        /// Search field glyph on the history screen.
        static let search = "magnifyingglass"

        /// Favorite indicator (not favorited).
        static let favorite = "star"

        /// Favorite indicator (favorited).
        static let favoriteFilled = "star.fill"

        /// Native share affordance.
        static let share = "square.and.arrow.up"
    }

    // MARK: - Status

    /// Status and feedback symbols.
    enum Status {

        /// Success.
        static let success = "checkmark.circle.fill"

        /// Warning.
        static let warning = "exclamationmark.triangle.fill"

        /// Danger.
        static let danger = "xmark.octagon.fill"

        /// Information.
        static let info = "info.circle.fill"
    }
}
