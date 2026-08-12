import SwiftUI

/// Label above a rounded bordered input with optional trailing icon.
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var trailingIcon: String? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            HStack {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .keyboardType(keyboard)
                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.brandOrange)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderGray, lineWidth: 1)
            )
        }
    }
}

/// Tappable field that opens a picker menu (dropdown look with chevron).
struct DropdownField: View {
    let label: String
    let placeholder: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection = option }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? placeholder : selection)
                        .font(.system(size: 15))
                        .foregroundStyle(selection.isEmpty ? Color.inkTertiary : Color.inkPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkSecondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderGray, lineWidth: 1)
                )
            }
        }
    }
}

/// Native date picker inside a bordered field row.
struct DatePickerField: View {
    let label: String
    @Binding var date: Date
    var range: PartialRangeFrom<Date> = Date()...

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundStyle(Color.brandOrange)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            DatePicker("", selection: $date, in: range, displayedComponents: .date)
                .labelsHidden()
                .tint(Color.brandOrange)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderGray, lineWidth: 1)
        )
    }
}

/// Native time picker inside a bordered field row.
struct TimePickerField: View {
    let label: String
    @Binding var time: Date

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 15))
                .foregroundStyle(Color.brandOrange)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 2)
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.brandOrange)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(height: 54)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderGray, lineWidth: 1)
        )
    }
}

/// A known Doha location that can be suggested while typing.
struct LocationSuggestion: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let detail: String
    let latitude: Double
    let longitude: Double

    static let dohaSuggestions: [LocationSuggestion] = [
        LocationSuggestion(name: "West Bay", detail: "Business district · Doha", latitude: 25.3208, longitude: 51.5305),
        LocationSuggestion(name: "The Pearl", detail: "Island district · Doha", latitude: 25.3697, longitude: 51.5445),
        LocationSuggestion(name: "Lusail", detail: "Marina district · Doha", latitude: 25.3785, longitude: 51.5250),
        LocationSuggestion(name: "Msheireb", detail: "Downtown · Doha", latitude: 25.2854, longitude: 51.5260),
        LocationSuggestion(name: "Al Sadd", detail: "Central Doha", latitude: 25.2776, longitude: 51.5104),
        LocationSuggestion(name: "Katara", detail: "Cultural village · Doha", latitude: 25.3594, longitude: 51.5257),
        LocationSuggestion(name: "Al Dafna", detail: "Diplomatic area · Doha", latitude: 25.3128, longitude: 51.5240),
        LocationSuggestion(name: "LIV Residence", detail: "West Bay · Doha", latitude: 25.3319, longitude: 51.5288),
        LocationSuggestion(name: "Darwish Tower", detail: "The Pearl · Doha", latitude: 25.3697, longitude: 51.5445),
        LocationSuggestion(name: "Forty Four West Bay Tower", detail: "West Bay · Doha", latitude: 25.3247, longitude: 51.5300),
        LocationSuggestion(name: "Marina Twin Tower", detail: "Lusail · Doha", latitude: 25.3785, longitude: 51.5250),
        LocationSuggestion(name: "Al Jazi Gardens", detail: "Msheireb · Doha", latitude: 25.2854, longitude: 51.5260)
    ]

    static func matching(_ text: String) -> [LocationSuggestion] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return dohaSuggestions.filter { suggestion in
            suggestion.name.localizedCaseInsensitiveContains(trimmed)
                || suggestion.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

/// Light-gray row with a trailing iOS switch.
struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Toggle("", isOn: $isOn.animation(.spring(response: 0.3, dampingFraction: 0.8)))
                .labelsHidden()
                .tint(Color.brandOrange)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 14))
    }
}

/// Hourly / Daily / Monthly pill selector. Selected = orange border + pale fill.
struct SegmentedPillSelector: View {
    @Binding var selection: ParkingDuration

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ParkingDuration.allCases) { duration in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = duration
                    }
                } label: {
                    Text(duration.rawValue)
                        .font(.system(size: 15, weight: selection == duration ? .bold : .medium))
                        .foregroundStyle(selection == duration ? Color.brandOrange : Color.inkPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selection == duration ? Color.orangeFaint : Color.white)
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selection == duration ? Color.brandOrange : Color.borderGray, lineWidth: selection == duration ? 1.5 : 1)
                        )
                }
            }
        }
    }
}

/// Dashed dropzone. Once "uploaded" (mock) shows the file chip with a trash icon.
struct UploadDropzone: View {
    let helper: String
    let mockFileName: String
    @Binding var uploadedFile: String?

    var body: some View {
        Group {
            if let file = uploadedFile {
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.brandOrange)
                    Text(file)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.inkPrimary)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            uploadedFile = nil
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.failureRed)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 58)
                .background(Color.cardGray)
                .clipShape(.rect(cornerRadius: 12))
            } else {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        uploadedFile = mockFileName
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium))
                        Text(helper)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.fieldGray.opacity(0.6))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                            .foregroundStyle(Color.inkTertiary.opacity(0.6))
                    )
                }
            }
        }
    }
}

/// Phone field with Qatar flag + +974 prefix.
struct PhoneField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Text("🇶🇦")
                        .font(.system(size: 18))
                    Text("+974")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.inkPrimary)
                }
                Rectangle()
                    .fill(Color.borderGray)
                    .frame(width: 1, height: 26)
                TextField("5583 3202", text: $text)
                    .font(.system(size: 15))
                    .keyboardType(.phonePad)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderGray, lineWidth: 1)
            )
        }
    }
}

/// Multiline description input.
struct TextAreaField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(4...7)
                .padding(14)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderGray, lineWidth: 1)
                )
        }
    }
}

/// Selectable saved-vehicle chip (Review & Pay).
struct VehicleChip: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(vehicle.model)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.inkPrimary)
                Text(vehicle.plate)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color.orangeFaint : Color.cardGray)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brandOrange : Color.clear, lineWidth: 1.6)
            )
        }
    }
}
