import SwiftUI

/// 3-step Add New Listing wizard: details → availability → pricing → success.
struct AddListingWizardView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var showLeaveDialog: Bool = false
    @State private var isPublished: Bool = false

    // Step 1
    @State private var building: String = ""
    @State private var level: String = ""
    @State private var spotNumber: String = ""
    @State private var accessType: String = ""
    @State private var vehicleSize: String = ""
    @State private var hasCharging: Bool = false
    @State private var securityType: String = ""
    @State private var descriptionText: String = ""
    @State private var photoFile: String?

    // Step 2 — availability rules (hours per weekday, full-day rules, blocked dates)
    @State private var schedule: AvailabilitySchedule = .workHours()

    private var hourlyOn: Bool { schedule.allowsHourly }
    private var dailyOn: Bool { schedule.allowsDaily }

    // Step 3
    @State private var hourlyPrice: String = ""
    @State private var dailyPrice: String = ""

    private var step1Valid: Bool {
        !building.isEmpty && !spotNumber.isEmpty && !accessType.isEmpty
    }

    private var step2Valid: Bool {
        guard hourlyOn || dailyOn else { return false }
        if hourlyOn && schedule.hasNoOpenDays { return false }
        if dailyOn && schedule.dailyDays.isEmpty { return false }
        return true
    }

    private var step3Valid: Bool {
        (!hourlyOn || !hourlyPrice.isEmpty) && (!dailyOn || !dailyPrice.isEmpty)
    }

    var body: some View {
        Group {
            if isPublished {
                ResultView(
                    isSuccess: true,
                    title: "Listing Published",
                    message: "Your parking spot is now live. Renters in your building can find and book it right away.",
                    primaryTitle: "Done",
                    primaryAction: { dismiss() }
                )
            } else {
                wizard
            }
        }
        .background(Color.white)
        .dialogOverlay(isPresented: showLeaveDialog) {
            ConfirmationDialogView(
                icon: .warning,
                title: "Discard listing?",
                message: "Your progress won't be saved. Are you sure you want to leave?",
                primaryTitle: "Keep Editing",
                primaryAction: { showLeaveDialog = false },
                secondaryTitle: "Leave",
                secondaryAction: {
                    showLeaveDialog = false
                    dismiss()
                }
            )
        }
    }

    private var wizard: some View {
        VStack(spacing: 0) {
            TopBar(leadingIcon: "xmark", onLeading: { showLeaveDialog = true })

            VStack(alignment: .leading, spacing: 14) {
                Text("Add New Listing")
                    .font(.pageTitle)
                    .foregroundStyle(Color.inkPrimary)
                WizardProgressBar(progress: Double(step + 1) / 3.0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            ScrollView {
                Group {
                    switch step {
                    case 0: detailsStep
                    case 1: availabilityStep
                    default: pricingStep
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            HStack(spacing: 12) {
                if step > 0 {
                    SecondaryButton(title: "Back") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step -= 1 }
                    }
                }
                PrimaryButton(title: step == 2 ? "Publish" : "Next", isEnabled: currentStepValid) {
                    if step == 2 {
                        publish()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step += 1 }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
    }

    private var currentStepValid: Bool {
        switch step {
        case 0: return step1Valid
        case 1: return step2Valid
        default: return step3Valid
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Parking Spot Details")

            DropdownField(
                label: "Building Name", placeholder: "Select building",
                options: ["LIV Residence", "Darwish Tower", "Forty Four West Bay Tower", "Marina Twin Tower", "Al Jazi Gardens"],
                selection: $building
            )
            FormField(label: "Level", placeholder: "e.g., Basement 2", text: $level)
            FormField(label: "Spot Number", placeholder: "e.g., P2-032", text: $spotNumber)
            DropdownField(
                label: "Access type", placeholder: "Choose access type",
                options: ["Check-in with Security", "Remote gate", "Key handover", "Access card"],
                selection: $accessType
            )
            DropdownField(
                label: "Maximum Vehicle Size", placeholder: "Choose",
                options: ["Up to 2.0m height", "Up to 2.2m height", "Up to 2.4m height", "No height limit"],
                selection: $vehicleSize
            )
            ToggleRow(label: "Charging Station Available", isOn: $hasCharging)
            DropdownField(
                label: "Security Type", placeholder: "Choose security type",
                options: ["CCTV monitored", "Guard on site", "Gated access", "None"],
                selection: $securityType
            )
            TextAreaField(
                label: "Description",
                placeholder: "Describe the spot: location, ease of access, nearby elevator, ideal vehicle type...",
                text: $descriptionText
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Spot Photos")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                UploadDropzone(helper: "Upload spot pictures", mockFileName: "spot_photos_3.jpg", uploadedFile: $photoFile)
            }
        }
    }

    private var availabilityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Parking Spot Availability")
                Text("Most owners rent out the spot while they're at work. Set the hours your spot is actually free — renters only see those windows.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
            }

            AvailabilityForm(schedule: $schedule)
        }
    }

    private var pricingStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Pricing")
            Text("2ndParking takes a 5% service commission on every booking.")
                .font(.helperText)
                .foregroundStyle(Color.inkSecondary)

            HStack(spacing: 9) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brandOrange)
                Text(schedule.compactSummary)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.inkPrimary)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.cardGray)
            .clipShape(.rect(cornerRadius: 12))

            if hourlyOn {
                FormField(label: "Hourly Price (QAR)", placeholder: "e.g., 10", text: $hourlyPrice, keyboard: .numberPad)
            }
            if dailyOn {
                FormField(label: "Daily Price (QAR)", placeholder: "e.g., 60", text: $dailyPrice, keyboard: .numberPad)
            }

            if let estimate = estimateLine {
                HStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.brandOrange)
                    Text(estimate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.inkPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orangeFaint)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    private var estimateLine: String? {
        if dailyOn, let price = Double(dailyPrice), price > 0 {
            let net = price * 20 * 0.95
            return String(format: "You'd earn ≈ %.0f QAR/month after commission", net)
        }
        if hourlyOn, let price = Double(hourlyPrice), price > 0 {
            return String(format: "Similar spots earn ≈ %.0f QAR/week at this rate", price * 20 * 0.95)
        }
        return nil
    }

    private func publish() {
        store.addListing(
            building: building,
            level: level,
            spotNumber: spotNumber.uppercased(),
            accessType: accessType,
            vehicleSize: vehicleSize.isEmpty ? "Up to 2.2m height" : vehicleSize,
            hasCharging: hasCharging,
            securityType: securityType.isEmpty ? "CCTV monitored" : securityType,
            description: descriptionText,
            hourly: hourlyOn ? Double(hourlyPrice) : nil,
            daily: dailyOn ? Double(dailyPrice) : nil,
            schedule: schedule
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPublished = true
        }
    }
}
