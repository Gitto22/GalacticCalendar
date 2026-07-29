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

        /// Previous period.
        static let previous = "chevron.left"

        /// Next period.
        static let next = "chevron.right"

        /// Affordance reserved for changing the visible month.
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

        /// Category selector glyph.
        static let category = "rocket"

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

        /// Duplicate event affordance.
        static let duplicate = "plus.square.on.square"

        /// Event calendar day selector.
        static let eventDate = "calendar"

        /// Event start time selector.
        static let startTime = "clock"

        /// Event end time selector.
        static let endTime = "clock.fill"

        /// Event time zone selector.
        static let timeZone = "globe"
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

        /// Opening quotation mark for Universe Messages.
        static let quote = "quote.opening"

        /// Inspiration badge glyph.
        static let inspiration = "sparkles"
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
